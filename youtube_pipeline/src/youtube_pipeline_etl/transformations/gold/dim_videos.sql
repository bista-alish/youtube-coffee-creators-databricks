create or refresh materialized view gold.dim_videos
comment 'One row per video in the latest snapshot.'
as
with

videos as (
  select
    video_id,
    channel_id,
    title,
    published_at_utc,
    duration_secs,
    live_broadcast_content,
    extracted_at_utc
  from silver.videos
),

channels as (
  select
    channel_id,
    title as channel_title
  from silver.channels
),

final as (
  select
    v.video_id,
    v.channel_id,
    c.channel_title,
    v.title as video_title,
    v.published_at_utc,
    date_format(v.published_at_utc, 'EEEE') as publish_day_utc,
    weekday(v.published_at_utc) + 1 as publish_day_num_utc,
    hour(v.published_at_utc) as publish_hour_utc,
    v.duration_secs,
    case
      when v.live_broadcast_content <> 'none' then null
      when v.duration_secs <= 180 then '0-3 min'
      when v.duration_secs <= 600 then '3-10 min'
      when v.duration_secs <= 1200 then '10-20 min'
      when v.duration_secs <= 2400 then '20-40 min'
      else '40+ min'
    end as length_band,
    case
      when v.live_broadcast_content <> 'none' then null
      when v.duration_secs <= 180 then 1
      when v.duration_secs <= 600 then 2
      when v.duration_secs <= 1200 then 3
      when v.duration_secs <= 2400 then 4
      else 5
    end as length_band_sort,
    case
      when v.live_broadcast_content <> 'none' then null
      else v.duration_secs <= 180
    end as is_short_estimate,
    datediff(v.extracted_at_utc, v.published_at_utc) as age_days,
    v.live_broadcast_content
  from videos as v
  left join channels as c
    on v.channel_id = c.channel_id
)

select * from final;