-- Zero-disruption isolated database setup for Medical CRM
SELECT 'CREATE DATABASE medicalcrm'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'medicalcrm')\gexec

DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'medicalcrm_user') THEN
      CREATE ROLE medicalcrm_user WITH LOGIN PASSWORD 'medicalcrm_secure_pass';
   END IF;
END
$do$;

GRANT ALL PRIVILEGES ON DATABASE medicalcrm TO medicalcrm_user;
ALTER DATABASE medicalcrm OWNER TO medicalcrm_user;
