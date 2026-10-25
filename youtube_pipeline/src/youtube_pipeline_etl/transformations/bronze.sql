create or refresh streaming table bronze.video_snapshots
comment 'Raw video snapshots from YouTube Data API'
as select 
    *,
    _metadata.file_path as _source_file,
    current_timestamp() as _ingested_at
from stream read_files(
    '/Volumes/youtube_coffee_creators/bronze/landing/video_snapshots/',
    format => 'json',
    pathGlobFilter => '*.jsonl'
);

create or refresh streaming table bronze.channel_snapshots
comment 'Raw channel snapshots from YouTube Data API'
as select 
    *,
    _metadata.file_path as _source_file,
    current_timestamp() as _ingested_at
from stream read_files(
    '/Volumes/youtube_coffee_creators/bronze/landing/channel_snapshots/',
    format => 'json',
    pathGlobFilter => '*.jsonl'
);