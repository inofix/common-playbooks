
-- # create functions

-- Create a function to manage partitions and subpartitions
CREATE OR REPLACE FUNCTION manage_recordings_partitions()
RETURNS void AS $$
DECLARE
    current_year integer;
    next_year integer;
    project_id integer;
    partition_name text;
    subpartition_name text;
BEGIN
    current_year := EXTRACT(YEAR FROM CURRENT_DATE);
    next_year := current_year + 1;

    -- Loop through all project IDs
    FOR project_id IN SELECT DISTINCT id FROM projects
    LOOP
        -- Create the partition for the projectid if it does not exixt
        partition_name := 'recordings_projectid' || project_id;
        IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = partition_name) THEN
            EXECUTE 'CREATE TABLE ' || partition_name || ' PARTITION OF recordings FOR VALUES IN (' || project_id || ') PARTITION BY RANGE (timestamp)';
        END IF;

        -- Create the sub-partition for the current year if it does not exist
        subpartition_name := 'recordings_projectid' || project_id || '_year' || TO_CHAR(current_year, 'FM0000');
        IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = subpartition_name) THEN
            EXECUTE 'CREATE TABLE ' || subpartition_name || ' PARTITION OF ' || partition_name || ' FOR VALUES FROM (''' || TO_CHAR(current_year, 'FM0000') || '-01-01'') TO (''' || TO_CHAR(current_year + 1, 'FM0000') || '-01-01'')';
        END IF;

        -- Create the sub-partition for the next year if it does not exist
        subpartition_name := 'recordings_projectid' || project_id || '_year' || TO_CHAR(next_year, 'FM0000');
        IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = subpartition_name) THEN
            EXECUTE 'CREATE TABLE ' || subpartition_name || ' PARTITION OF ' || partition_name || ' FOR VALUES FROM (''' || TO_CHAR(next_year, 'FM0000') || '-01-01'') TO (''' || TO_CHAR(next_year + 1, 'FM0000') || '-01-01'')';
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- new projects create recording partitions
CREATE OR REPLACE FUNCTION insert_project()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM manage_recordings_partitions();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- processing staged recordings and clean up or warn
CREATE OR REPLACE FUNCTION process_staged_recordings()
RETURNS VOID AS $$
DECLARE
    staging_valid_ids INTEGER[];
    staging_invalid_ids INTEGER[];
BEGIN
    -- Warn on 'many' staging table entries (queue).
    IF (SELECT COUNT(*) FROM recordings_staging) > 10000 THEN
        RAISE WARNING 'Too many entries in staging table, consider increasing interval or optimizing job';
    END IF;
    -- Create a lock file to block new processes, resp. quit if another process is running..
    PERFORM pg_advisory_lock(1);
    BEGIN        
    -- Select the IDs of the valid and invalid records
        SELECT array_agg(rs.id) INTO staging_valid_ids
        FROM recordings_staging rs
        WHERE EXISTS (
            SELECT 1
            FROM sources s
            WHERE s.uuid = rs.sourceuuid
        ) AND (rs.value IS NOT NULL OR rs.altvalue IS NOT NULL) AND rs.timestamp IS NOT NULL AND rs.sourceuuid IS NOT NULL;

        SELECT array_agg(id) INTO staging_invalid_ids
        FROM recordings_staging rs
        WHERE NOT EXISTS (
            SELECT 1
            FROM sources s
            WHERE s.uuid = rs.sourceuuid
        );

        -- Insert matching data into recordings table
        INSERT INTO recordings (timestamp, value, altvalue, lat, lon, alt, geohash, projectid, sourceid, meta)
        SELECT rs.timestamp, rs.value, rs.altvalue, rs.lat, rs.lon, rs.alt, rs.geohash, s.projectid, s.id, rs.meta
        FROM recordings_staging rs
        JOIN sources s ON rs.sourceuuid = s.uuid
        WHERE rs.id = ANY(staging_valid_ids)
        ON CONFLICT (timestamp, projectid, sourceid) DO NOTHING;

        -- Insert non-matching data into _recordings_orphaned table
        INSERT INTO _recordings_orphaned (timestamp, value, altvalue, lat, lon, alt, geohash, sourceuuid, meta)
        SELECT rs.timestamp, rs.value, rs.altvalue, rs.lat, rs.lon, rs.alt, rs.geohash, rs.sourceuuid, rs.meta
        FROM recordings_staging rs
        WHERE rs.id = ANY(staging_invalid_ids);

        -- Delete the processed records from the staging table
        DELETE FROM recordings_staging
        WHERE id = ANY(staging_valid_ids) OR id = ANY(staging_invalid_ids);

    EXCEPTION
        WHEN foreign_key_violation THEN
            ROLLBACK;
            RAISE WARNING 'Foreign key violation: %', SQLERRM;
        WHEN invalid_table_definition THEN
            ROLLBACK;
            RAISE WARNING 'Invalid table definition: %', SQLERRM;
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE WARNING 'Error: %', SQLERRM;
    END;
    -- Clean up lock file
    PERFORM pg_advisory_unlock(1);
    RETURN;
END;
$$ LANGUAGE plpgsql;



