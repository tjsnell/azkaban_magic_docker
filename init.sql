-- Azkaban database initialization script
CREATE DATABASE IF NOT EXISTS azkaban;
USE azkaban;

-- Grant permissions
GRANT ALL PRIVILEGES ON azkaban.* TO 'azkaban'@'%';
FLUSH PRIVILEGES;