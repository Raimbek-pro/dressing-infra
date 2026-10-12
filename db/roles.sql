-- Database roles (run as postgres; :app_pw is passed by 40_postgres.sh).
-- dressing_owner owns the data; dressing_app (the backend) may change rows, not tables.

SELECT 'CREATE ROLE dressing_owner NOLOGIN'
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'dressing_owner') \gexec
SELECT 'CREATE ROLE dressing_app LOGIN'
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'dressing_app') \gexec
ALTER ROLE dressing_app PASSWORD :'app_pw';

SELECT 'CREATE DATABASE dressing OWNER dressing_owner'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'dressing') \gexec
REVOKE ALL ON DATABASE dressing FROM PUBLIC;
GRANT CONNECT ON DATABASE dressing TO dressing_app;

\connect dressing
CREATE SCHEMA IF NOT EXISTS app AUTHORIZATION dressing_owner;
GRANT USAGE ON SCHEMA app TO dressing_app;
ALTER DEFAULT PRIVILEGES FOR ROLE dressing_owner IN SCHEMA app
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO dressing_app;
ALTER DEFAULT PRIVILEGES FOR ROLE dressing_owner IN SCHEMA app
    GRANT USAGE ON SEQUENCES TO dressing_app;
ALTER ROLE dressing_app SET search_path = app;
