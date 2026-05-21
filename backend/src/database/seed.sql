-- Seed data for Royal Shetkari App

-- Initial Super Admin (Password: admin123)
-- Hash generated for 'admin123'
INSERT INTO users (full_name, mobile, email, password, is_admin, role)
VALUES ('System Admin', '8605889356', 'admin@royalshetkari.com', '$2b$10$EPfLwvZBySa7WvE3/RP8O.D2WjE2WJz.vE2WJz.vE2WJz.vE2WJz.', TRUE, 'superuser')
ON CONFLICT (mobile) DO NOTHING;
