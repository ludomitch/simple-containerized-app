CREATE TABLE strings (
    id SERIAL PRIMARY KEY,
    string_value TEXT NOT NULL
);

INSERT INTO strings (string_value) VALUES ('hello world');