create or refresh materialized view silver.channels
comment 'Current state: one row per channel in the latest snapshot.'
as
select *
from silver.channel_snapshots
where snapshot_id = (select max(snapshot_id) from silver.channel_snapshots);