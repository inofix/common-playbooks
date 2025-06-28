-- # create tables

-- meta table to store internal info, like the schema version
CREATE TABLE _meta (
    schemaversion TEXT PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL,
    adminname TEXT,
    meta JSONB
);

-- persons to know, like users or project representatives
CREATE TABLE persons (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name TEXT NOT NULL,
    uuid UUID,
    extid TEXT,
    extidtype VARCHAR(32),
    isnatural BOOLEAN,
--    version INTEGER NOT NULL DEFAULT 0,
--    created TIMESTAMPTZ NULL,
--    lastmodifieddate TIMESTAMPTZ NULL,
--    lastmodifieduser INTEGER NULL,
    PRIMARY KEY(id)
--    PRIMARY KEY(id, version)
);

-- all sorts of contact data
CREATE TABLE contacts (
    id INTEGER NOT NULL,
    name TEXT NOT NULL,
    icard text,
--    version INTEGER NOT NULL DEFAULT 0,
--    created TIMESTAMPTZ NULL,
--    lastmodifieddate TIMESTAMPTZ NULL,
--    lastmodifieduser INTEGER NULL,
    PRIMARY KEY(id)
--    PRIMARY KEY(id, version)
);

-- all data needs a project context
CREATE TABLE projects (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    uuid UUID,
    name TEXT NOT NULL,
    representativepersonid INTEGER REFERENCES persons(id),
    publiccontactid INTEGER REFERENCES contacts(id),
    meta JSONB,
--    version INTEGER NOT NULL DEFAULT 0,
--    created TIMESTAMPTZ NULL,
--    lastmodifieddate TIMESTAMPTZ NULL,
--    lastmodifieduser INTEGER NULL,
    PRIMARY KEY(id)
--    PRIMARY KEY(id, version)
);

-- connecting people with contacts
CREATE TABLE personcontacts (
    personsubjectid INTEGER REFERENCES persons(id) NOT NULL,
    contactobjectid INTEGER REFERENCES contacts(id),
    projectcontextid INTEGER REFERENCES projects(id),
    isprimarycontact BOOLEAN DEFAULT False,
    PRIMARY KEY(personsubjectid, contactobjectid, projectcontextid)
);

-- the actual users on the system
CREATE TABLE users (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    idtoken TEXT,
    idtokenhash VARCHAR(8),
    idtokentype VARCHAR(16),
    realpersonid INTEGER REFERENCES persons(id),
    PRIMARY KEY(id)
);

-- role based user permissions
CREATE TABLE roles (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    name TEXT NOT NULL,
    projectid INTEGER REFERENCES projects(id),
    isowner BOOLEAN DEFAULT False,
    canread BOOLEAN,
    canedit BOOLEAN,
    cancreate BOOLEAN,
    candelete BOOLEAN,
    cangrant BOOLEAN,
--    version INTEGER NOT NULL DEFAULT 0,
--    created TIMESTAMPTZ NULL,
--    lastmodifieddate TIMESTAMPTZ NULL,
--    lastmodifieduser INTEGER NULL,
    PRIMARY KEY(id)
--    PRIMARY KEY(id, version)
);

-- connecting users to roles
CREATE TABLE userroles (
    userid INTEGER REFERENCES users(id) NOT NULL,
    roleid INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    PRIMARY KEY(userid, roleid)
);

-- the type of data sources available
CREATE TABLE sourcetypes (
    id INTEGER GENERATED ALWAYS AS IDENTITY, -- db internal
    name TEXT, -- kind of source: location/site, vehicle, node, sensor, actuator api, etc.
    uuid UUID, -- e.g. comparable sensors
    devicetype TEXT, -- only for devices, e.g. EdgeGateway
    devicesubtype TEXT, -- see above, e.g. RaspberryPi3
    realmname TEXT, -- Lifebase service
    realmuuid UUID, -- Lifebase service
    contentencoding VARCHAR(32),
    contenttype VARCHAR(32),
    contentrdfxtypes TEXT, -- RDF
    unit VARCHAR(16), --
    unitencoding VARCHAR(16),
    tolerance INTEGER,
    meta JSONB,
--    version INTEGER NOT NULL DEFAULT 0,
--    created TIMESTAMPTZ NULL,
--    lastmodifieddate TIMESTAMPTZ NULL,
--    lastmodifieduser INTEGER NULL,
    PRIMARY KEY(id)
--    PRIMARY KEY(id, version)
);

-- the data sources explaining all details of the recordings
--    uuid UUID DEFAULT public.uuid_generate_v4(),
CREATE TABLE sources (
    id INTEGER GENERATED ALWAYS AS IDENTITY, -- db internal
    uuid UUID DEFAULT gen_random_uuid(), -- global id
    extid TEXT, -- alternative for preexisting external reference if needed
    tree LTREE UNIQUE, -- hierarchical info
    name TEXT, -- short name, usually part of 'tree'..
    context TEXT, --
    sourcetypeid INTEGER REFERENCES sourcetypes(id) NOT NULL,
    projectid INTEGER REFERENCES projects(id) NOT NULL,
    parentid INTEGER REFERENCES sources(id),
    alt DOUBLE PRECISION,
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    mapzoom INTEGER, -- for map displays, usually osm.org zoom
    geohash VARCHAR(12),
    timezone TEXT, -- e.g. 'Europe/Zurich'
    startdate TIMESTAMPTZ,
    stopdate TIMESTAMPTZ,
    samplerate INTEGER,
    meta JSONB,
    maintainerpersonid INTEGER REFERENCES persons(id),
    softwareversion TEXT,
    hardwareversion TEXT,
--    version INTEGER NOT NULL DEFAULT 0,
--    created TIMESTAMPTZ NULL,
--    lastmodifieddate TIMESTAMPTZ NULL,
--    lastmodifieduser INTEGER NULL,
    PRIMARY KEY(id)
--    PRIMARY KEY(id, version)
);

-- optional permission
CREATE TABLE personpermissions (
    roleid INTEGER REFERENCES roles(id) NOT NULL,
    projectid INTEGER REFERENCES projects(id) NOT NULL,
    personid INTEGER REFERENCES persons(id) NOT NULL,
    PRIMARY KEY(roleid, projectid, personid)
);

-- optional permission
CREATE TABLE contactpermissions (
    roleid INTEGER REFERENCES roles(id) NOT NULL,
    projectid INTEGER REFERENCES projects(id) NOT NULL,
    contactid INTEGER REFERENCES contacts(id) NOT NULL,
    PRIMARY KEY(roleid, projectid, contactid)
);

-- optional permission
CREATE TABLE sourcepermissions (
    roleid INTEGER REFERENCES roles(id) NOT NULL,
    projectid INTEGER REFERENCES projects(id) NOT NULL,
    sourceid INTEGER REFERENCES sources(id) NOT NULL,
    PRIMARY KEY(roleid, projectid, sourceid)
);

-- the actual data
--   projectid: double check that the project exists, we also create partitions here of
--   sourceid: inserts from sources will look up their and project ids on inserts
CREATE TABLE recordings (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    timestamp TIMESTAMPTZ NOT NULL,
    value DOUBLE PRECISION,
    altvalue JSONB,
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    alt DOUBLE PRECISION,
    geohash VARCHAR(12),
    projectid INTEGER REFERENCES projects(id) NOT NULL,
    sourceid INTEGER REFERENCES sources(id) NOT NULL,
    meta JSONB,
    UNIQUE (timestamp, projectid, sourceid),
    PRIMARY KEY(id, timestamp, projectid)
) PARTITION BY LIST (projectid);

-- temporary storage for incoming data
CREATE TABLE recordings_staging (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    timestamp TIMESTAMPTZ NOT NULL,
    value DOUBLE PRECISION,
    altvalue JSONB,
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    alt DOUBLE PRECISION,
    geohash VARCHAR(12),
    sourceuuid UUID NOT NULL,
    meta JSONB,
    PRIMARY KEY(id)
);

-- temporary storage for incoming data
CREATE TABLE _recordings_orphaned (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    timestamp TIMESTAMPTZ NOT NULL,
    value DOUBLE PRECISION,
    altvalue JSONB,
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    alt DOUBLE PRECISION,
    geohash VARCHAR(12),
    sourceuuid UUID NOT NULL,
    meta JSONB,
    PRIMARY KEY(id)
);

