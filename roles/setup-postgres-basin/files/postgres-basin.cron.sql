
-- # enable cron on unix socket

-- periodically process staged data
SELECT cron.schedule('0 0 28-31 * *', $$SELECT manage_recordings_partitions()$$);
SELECT cron.schedule('* * * * *', $$SELECT process_staged_recordings()$$);
-- unset hostname on all jobs so far to use unix socket
UPDATE cron.job SET nodename = '';

