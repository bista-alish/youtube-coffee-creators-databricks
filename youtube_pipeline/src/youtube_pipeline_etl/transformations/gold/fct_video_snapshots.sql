create or refresh materialized view gold.fct_video_snapshots (
  constraint non_negative_views_gained expect (views_gained >= 0 or views_gained is null)
)
comment 'Periodic snapshot fact: one row per video per extractor run.'
as
with

snapshots as (
  select
    video_id,
    channel_id,
    snapshot_id,
    extracted_at_utc,
    view_count,
    like_count,
    comment_count
  from silver.video_snapshots
),

with_previous as (
  select
    *,
    lag(view_count) over w as previous_view_count,
    lag(like_count) over w as previous_like_count,
    lag(comment_count) over w as previous_comment_count,
    lag(extracted_at_utc) over w as previous_extracted_at_utc
  from snapshots
  window w as (partition by video_id order by extracted_at_utc)
),

final as (
  select
    video_id,
    channel_id,
    snapshot_id,
    extracted_at_utc,
    view_count,
    like_count,
    comment_count,
    view_count - previous_view_count as views_gained,
    like_count - previous_like_count as likes_gained,
    comment_count - previous_comment_count as comments_gained,
    round(timestampdiff(minute, previous_extracted_at_utc, extracted_at_utc) / 60.0, 2) as hours_since_previous,
    try_divide(like_count + comment_count, view_count) as engagement_rate
  from with_previous
)

select * from final;