create or refresh materialized view silver.channel_snapshots (
  constraint valid_channel_id expect (channel_id is not null) on violation drop row
)
comment 'Typed channel snapshots: one row per channel per extractor run.'
as
with

source as (
  select
    channel_id,
    title,
    subscriber_count,
    video_count,
    view_count,
    _extracted_at,
    _snapshot_id,
    _source_file,
    _ingested_at
  from bronze.channel_snapshots
),

typed as (
  select
    channel_id,
    title,
    try_cast(subscriber_count as bigint) as subscriber_count,
    try_cast(video_count as bigint) as video_count,
    try_cast(view_count as bigint) as view_count,
    cast(_extracted_at as timestamp) as extracted_at_utc,
    _snapshot_id as snapshot_id,
    _source_file,
    _ingested_at
  from source
),

deduplicated as (
  select *
  from typed
  qualify row_number() over (
    partition by channel_id, snapshot_id
    order by _ingested_at desc
  ) = 1
),

final as (
  select
    channel_id,
    title,
    subscriber_count,
    video_count,
    view_count,
    extracted_at_utc,
    snapshot_id,
    _source_file
  from deduplicated
)

select * from final;