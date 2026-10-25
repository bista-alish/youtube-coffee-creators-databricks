create or refresh materialized view gold.channel_summary
comment 'One row per channel: current subscribers and catalog.'
as
with

channels as (
  select
    channel_id,
    title as channel_title,
    subscriber_count,
    video_count,
    view_count,
    extracted_at_utc
  from silver.channels
),

latest_stats as (
  select
    video_id,
    view_count,
    engagement_rate
  from gold.fct_video_snapshots
  where snapshot_id = (select max(snapshot_id) from gold.fct_video_snapshots)
),

videos as (
  select
    d.channel_id,
    d.is_short_estimate,
    s.view_count,
    s.engagement_rate
  from gold.dim_videos as d
  inner join latest_stats as s
    on d.video_id = s.video_id
  where d.is_short_estimate is not null
),

rollup as (
  select
    channel_id,
    count(*) as videos_analysed,
    count_if(is_short_estimate) as shorts,
    sum(view_count) as video_views,
    sum(case when is_short_estimate then view_count else 0 end) as shorts_views,
    median(engagement_rate) as median_engagement_rate,
    median(case when is_short_estimate then engagement_rate end) as median_engagement_rate_shorts,
    median(case when not is_short_estimate then engagement_rate end) as median_engagement_rate_long
  from videos
  group by channel_id
),

final as (
  select
    c.channel_id,
    c.channel_title,
    c.subscriber_count,
    c.video_count,
    c.view_count as channel_view_count,
    r.videos_analysed,
    r.shorts,
    try_divide(r.shorts, r.videos_analysed) as shorts_share_of_uploads,
    try_divide(r.shorts_views, r.video_views) as shorts_share_of_views,
    r.median_engagement_rate,
    r.median_engagement_rate_shorts,
    r.median_engagement_rate_long,
    c.extracted_at_utc as as_of_utc
  from channels as c
  left join rollup as r
    on c.channel_id = r.channel_id
)

select * from final;