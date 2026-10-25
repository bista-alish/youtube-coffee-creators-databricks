create or refresh materialized view silver.videos
comment 'Current state: one row per video in the latest snapshot.'
as
select *
from silver.video_snapshots
where snapshot_id = (select max(snapshot_id) from silver.video_snapshots);