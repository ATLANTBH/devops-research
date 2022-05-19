CREATE TABLE users (
    email VARCHAR(355) UNIQUE NOT NULL,
    password VARCHAR(256) NOT NULL
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    price NUMERIC(6, 2) NOT NULL,
    category INT NOT NULL
);

INSERT INTO users VALUES ('test@test.com', 'Test*123');
INSERT INTO products (title, price, category) VALUES ('Truco', 9.90, 13);
