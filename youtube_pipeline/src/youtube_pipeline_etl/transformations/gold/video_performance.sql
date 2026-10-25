create or refresh materialized view gold.video_performance
comment 'One row per published video (live and upcoming excluded) with its latest counts and rates. format is an estimate: Short means 180 seconds or less.'
as
with

latest as (
  select
    video_id,
    view_count,
    like_count,
    comment_count,
    engagement_rate,
    extracted_at_utc
  from gold.fct_video_snapshots
  where snapshot_id = (select max(snapshot_id) from gold.fct_video_snapshots)
),

final as (
  select
    d.video_id,
    d.channel_id,
    d.channel_title,
    d.video_title,
    d.published_at_utc,
    d.publish_day_utc,
    d.publish_day_num_utc,
    d.publish_hour_utc,
    d.duration_secs,
    d.length_band,
    d.length_band_sort,
    case when d.is_short_estimate then 'Short (est.)' else 'Long-form' end as format,
    l.view_count,
    l.like_count,
    l.comment_count,
    try_divide(l.like_count, l.view_count) as like_rate,
    try_divide(l.comment_count, l.view_count) as comment_rate,
    l.engagement_rate,
    d.age_days,
    try_divide(l.view_count, greatest(d.age_days, 1)) as views_per_day,
    l.extracted_at_utc as as_of_utc
  from gold.dim_videos as d
  inner join latest as l
    on d.video_id = l.video_id
  where d.is_short_estimate is not null
)

select * from final;