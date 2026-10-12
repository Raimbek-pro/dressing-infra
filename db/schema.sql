-- Dressing schema v1, owned by dressing_owner. Covers today's editor and the planned
-- Community (sharing, gifts/collectibles) and AR Wardrobe tabs.
-- Images and 3D models are NOT stored here: only their object-storage keys.
SET ROLE dressing_owner;
SET search_path = app;

CREATE TABLE IF NOT EXISTS users (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    apple_sub    text UNIQUE NOT NULL,              -- Sign in with Apple subject
    handle       text UNIQUE NOT NULL CHECK (handle ~ '^[a-z0-9_.]{3,30}$'),
    display_name text NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS follows (
    follower_id  bigint REFERENCES users ON DELETE CASCADE,
    followee_id  bigint REFERENCES users ON DELETE CASCADE,
    created_at   timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (follower_id, followee_id),
    CHECK (follower_id <> followee_id)
);

CREATE TABLE IF NOT EXISTS materials (               -- user-uploaded fabrics
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_id     bigint NOT NULL REFERENCES users ON DELETE CASCADE,
    name         text NOT NULL,
    field        text,                               -- "which world it came from"
    note         text,
    credit       text,
    image_key    text NOT NULL,                      -- object storage key
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS designs (                 -- one canvas
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_id     bigint NOT NULL REFERENCES users ON DELETE CASCADE,
    title        text NOT NULL DEFAULT 'Untitled',
    canvas       jsonb NOT NULL,                     -- garments, pieces -> material ids, positions
    visibility   text NOT NULL DEFAULT 'private' CHECK (visibility IN ('private','friends','public')),
    preview_key  text,
    model_key    text,                               -- USDZ for the AR wardrobe
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS designs_feed ON designs (visibility, created_at DESC);

-- Collectible gifts: a fixed edition of numbered items that move between users.
CREATE TABLE IF NOT EXISTS collectibles (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    design_id    bigint NOT NULL REFERENCES designs,
    edition_size int NOT NULL CHECK (edition_size > 0)
);
CREATE TABLE IF NOT EXISTS collectible_items (
    collectible_id bigint REFERENCES collectibles,
    serial         int,
    owner_id       bigint NOT NULL REFERENCES users,
    PRIMARY KEY (collectible_id, serial)
);
CREATE TABLE IF NOT EXISTS gift_transfers (          -- append-only history
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    collectible_id bigint NOT NULL,
    serial         int NOT NULL,
    from_user      bigint NOT NULL REFERENCES users,
    to_user        bigint NOT NULL REFERENCES users,
    message        text,
    sent_at        timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (collectible_id, serial) REFERENCES collectible_items
);

RESET ROLE;
