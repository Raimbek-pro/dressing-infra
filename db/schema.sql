-- Tables, owned by dressing_owner.
SET ROLE dressing_owner;

CREATE TABLE IF NOT EXISTS app.users (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    handle     text UNIQUE NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS app.designs (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_id   bigint NOT NULL REFERENCES app.users ON DELETE CASCADE,
    canvas     jsonb NOT NULL,          -- garments, pieces -> fabrics
    created_at timestamptz NOT NULL DEFAULT now()
);

RESET ROLE;
