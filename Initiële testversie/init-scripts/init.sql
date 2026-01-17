-- Database initialisatie script - TESTVERSIE
-- Simpele test data om database connectivity te verifiëren

-- Gebruik testdb (wordt al aangemaakt via POSTGRES_DB env var)

-- Creëer simpele test tabel
CREATE TABLE IF NOT EXISTS test_status (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'running',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test data
INSERT INTO test_status (service_name, status) VALUES
    ('Platform Frontend', 'ready'),
    ('Game Service', 'ready'),
    ('Backend API', 'ready'),
    ('Database', 'ready'),
    ('Message Queue', 'ready');

-- Test query om te verifiëren
SELECT 'Database initialisatie succesvol!' as message,
       COUNT(*) as services_count
FROM test_status;
