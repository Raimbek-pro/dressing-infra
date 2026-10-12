-- Dressing schema, owned by dressing_owner (the app role can use it, not change it).
SET ROLE dressing_owner;
SET search_path = app;

CREATE TABLE IF NOT EXISTS users (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    handle       text UNIQUE NOT NULL CHECK (handle ~ '^[a-z0-9_.]{3,30}$'),
    display_name text NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS designs (                 -- one canvas
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_id     bigint NOT NULL REFERENCES users ON DELETE CASCADE,
    title        text NOT NULL DEFAULT 'Untitled',
    canvas       jsonb NOT NULL,                     -- garments, pieces -> fabrics, positions
    visibility   text NOT NULL DEFAULT 'private' CHECK (visibility IN ('private','friends','public')),
    created_at   timestamptz NOT NULL DEFAULT now()
);

RESET ROLE;
