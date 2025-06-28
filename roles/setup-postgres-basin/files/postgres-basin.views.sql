-- # create views

-- the view to summarize recordings from all projects
CREATE VIEW
    all_recordings_view AS
SELECT
    recordings.timestamp,
    recordings.value,
    COALESCE(recordings.lat, sources.lat) AS lat,
    COALESCE(recordings.lon, sources.lon) AS lon,
    COALESCE(recordings.alt, sources.alt) AS alt,
    COALESCE(recordings.geohash, sources.geohash) AS geohash,
    sources.tree,
    sources.name
FROM
    sources
INNER JOIN
    recordings
ON sources.id = recordings.id;

