create or refresh materialized view silver.video_snapshots (
  constraint valid_video_id expect (video_id is not null) on violation drop row
)
comment 'Typed video snapshots: one row per video per extractor run.'
as
with

source as (
  select
    video_id,
    channel_id,
    title,
    published_at,
    duration,
    view_count,
    like_count,
    comment_count,
    live_broadcast_content,
    _extracted_at,
    _snapshot_id,
    _source_file,
    _ingested_at
  from bronze.video_snapshots
),

typed as (
  select
    video_id,
    channel_id,
    title,
    cast(published_at as timestamp) as published_at_utc,
    duration as duration_iso,
    case
      when duration is null then null
      else
        coalesce(try_cast(regexp_extract(duration, r'(\d+)D', 1) as int), 0) * 86400
        + coalesce(try_cast(regexp_extract(duration, r'(\d+)H', 1) as int), 0) * 3600
        + coalesce(try_cast(regexp_extract(duration, r'(\d+)M', 1) as int), 0) * 60
        + coalesce(try_cast(regexp_extract(duration, r'(\d+)S', 1) as int), 0)
    end as duration_secs,
    try_cast(view_count as bigint) as view_count,
    try_cast(like_count as bigint) as like_count,
    try_cast(comment_count as bigint) as comment_count,
    live_broadcast_content,
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
    partition by video_id, snapshot_id
    order by _ingested_at desc
  ) = 1
),

final as (
  select
    video_id,
    channel_id,
    title,
    published_at_utc,
    duration_iso,
    duration_secs,
    view_count,
    like_count,
    comment_count,
    live_broadcast_content,
    extracted_at_utc,
    snapshot_id,
    _source_file
  from deduplicated
)

select * from final;