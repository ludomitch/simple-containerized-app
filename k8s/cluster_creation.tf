// Add this variable declaration at the beginning of your file
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"  // Change this to your preferred default region
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.6"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.27"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    disk_size              = 50
    instance_types         = ["t3.medium"]
    vpc_security_group_ids = [aws_security_group.node_group_one.id]
  }

  eks_managed_node_groups = {
    one = {
      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }

  // Add this line to enable OIDC provider
  enable_irsa = true
}

// Add these data sources
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

// Update the Kubernetes provider configuration
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "aws_security_group" "node_group_one" {
  name_prefix = "node_group_one"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}


resource "aws_iam_policy" "eks_admin_policy" {
  name = "EKSAdminPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*",
          "ec2:*",
          "iam:*",
          "autoscaling:*",
          "elasticloadbalancing:*",
          "cloudwatch:*",
          "logs:*",
          "kms:*",
          "ssm:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "eks_admin_role" {
  name = "EKSAdminRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin_policy_attachment" {
  policy_arn = aws_iam_policy.eks_admin_policy.arn
  role       = aws_iam_role.eks_admin_role.name
}

// Add this new security group for the load balancer
resource "aws_security_group" "lb_sg" {
  name        = "eks-lb-sg"
  description = "Security group for EKS load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  // Allow traffic from anywhere. Restrict this as needed.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-lb-sg"
  }
}

resource "aws_lb" "eks_lb" {
  name               = "eks-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]  // Use the new security group
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

// Update the existing target group for the API service
resource "aws_lb_target_group" "api_tg" {
  name        = "eks-api-target-group"
  port        = 30000  // This matches the NodePort of your API service
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/healthz"  // Adjust this to your app's health check endpoint
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

// Add a new target group for Grafana
resource "aws_lb_target_group" "grafana_tg" {
  name        = "eks-grafana-target-group"
  port        = 30002  // This matches the NodePort of your Grafana service
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/api/health"  // Grafana health check endpoint
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.eks_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Welcome to EKS"
      status_code  = "200"
    }
  }
}

// Add listener rules for API and Grafana
resource "aws_lb_listener_rule" "api_rule" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "grafana_rule" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }

  condition {
    path_pattern {
      values = ["/grafana/*"]
    }
  }
}

resource "aws_autoscaling_attachment" "eks_asg_attachment_api" {
  autoscaling_group_name = module.eks.eks_managed_node_groups["one"].node_group_autoscaling_group_names[0]
  lb_target_group_arn    = aws_lb_target_group.api_tg.arn
}

resource "aws_autoscaling_attachment" "eks_asg_attachment_grafana" {
  autoscaling_group_name = module.eks.eks_managed_node_groups["one"].node_group_autoscaling_group_names[0]
  lb_target_group_arn    = aws_lb_target_group.grafana_tg.arn
}

output "load_balancer_dns" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.eks_lb.dns_name
}

// Add these output blocks at the end of the file
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}
