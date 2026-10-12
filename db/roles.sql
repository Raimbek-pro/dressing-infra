-- Database roles (run as postgres; :app_pw passed by 40_postgres.sh).
-- Same idea as Linux groups: NOLOGIN "group" roles hold privileges, LOGIN roles inherit them.

SELECT 'CREATE ROLE dressing_owner NOLOGIN'
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'dressing_owner') \gexec
SELECT 'CREATE ROLE dressing_readwrite NOLOGIN'
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'dressing_readwrite') \gexec
SELECT 'CREATE ROLE dressing_readonly NOLOGIN'
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'dressing_readonly') \gexec

-- Login roles
SELECT 'CREATE ROLE dressing_app LOGIN CONNECTION LIMIT 20 IN ROLE dressing_readwrite'
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'dressing_app') \gexec
ALTER ROLE dressing_app PASSWORD :'app_pw';
SELECT 'CREATE ROLE dba1 LOGIN IN ROLE dressing_owner'                -- peer auth, no password
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'dba1') \gexec

SELECT 'CREATE DATABASE dressing OWNER dressing_owner'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'dressing') \gexec

REVOKE ALL ON DATABASE dressing FROM PUBLIC;
REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;   -- by default every role may connect here
GRANT CONNECT ON DATABASE dressing TO dressing_readwrite, dressing_readonly, dressing_owner;

\connect dressing
REVOKE ALL ON SCHEMA public FROM PUBLIC;
CREATE SCHEMA IF NOT EXISTS app AUTHORIZATION dressing_owner;
GRANT USAGE ON SCHEMA app TO dressing_readwrite, dressing_readonly;

-- Tables created later by dressing_owner (migrations) get these grants automatically.
ALTER DEFAULT PRIVILEGES FOR ROLE dressing_owner IN SCHEMA app
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO dressing_readwrite;
ALTER DEFAULT PRIVILEGES FOR ROLE dressing_owner IN SCHEMA app
    GRANT USAGE, SELECT ON SEQUENCES TO dressing_readwrite;
ALTER DEFAULT PRIVILEGES FOR ROLE dressing_owner IN SCHEMA app
    GRANT SELECT ON TABLES TO dressing_readonly;

-- The app role never owns anything and cannot change the schema.
ALTER ROLE dressing_app SET search_path = app;
