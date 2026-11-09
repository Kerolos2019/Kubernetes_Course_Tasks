-- Tables and default data used by the WebApp API

CREATE TABLE IF NOT EXISTS messages (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  author      VARCHAR(50)  NOT NULL,
  content     VARCHAR(255) NOT NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO messages (author, content) VALUES
  ('admin',    'Welcome to the WebApp guestbook!'),
  ('k8s-labs', 'This message was created when the database was initialized.');
