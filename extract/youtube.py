from api import get_json
from config import MAX_VIDEOS_PER_CHANNEL, PAGE_SIZE


def get_channels(channel_ids):
    data = get_json("channels", {
        "part": "snippet,statistics,contentDetails",
        "id": ",".join(channel_ids),
    })
    channels = data.get("items", [])

    # The API returns 200 with no items for unknown IDs, so check explicitly
    missing = set(channel_ids) - {channel["id"] for channel in channels}
    if missing:
        raise ValueError(f"Channel IDs not found: {sorted(missing)}")
    return channels


def get_video_ids(uploads_playlist_id):
    video_ids = []
    page_token = None

    while True:
        data = get_json("playlistItems", {
            "part": "contentDetails",
            "playlistId": uploads_playlist_id,
            "maxResults": PAGE_SIZE,
            "pageToken": page_token,
        })
        video_ids += [item["contentDetails"]["videoId"] for item in data.get("items", [])]

        page_token = data.get("nextPageToken")
        if not page_token or len(video_ids) >= MAX_VIDEOS_PER_CHANNEL:
            break

    return video_ids[:MAX_VIDEOS_PER_CHANNEL]


def get_videos(video_ids):
    videos = []
    for start in range(0, len(video_ids), PAGE_SIZE):
        batch = video_ids[start:start + PAGE_SIZE]
        data = get_json("videos", {
            "part": "snippet,statistics,contentDetails",
            "id": ",".join(batch),
        })
        videos += data.get("items", [])
    return videos


def to_video_row(video):
    snippet = video["snippet"]
    stats = video["statistics"]
    return {
        "video_id": video["id"],
        "channel_id": snippet["channelId"],
        "title": snippet["title"],
        "published_at": snippet["publishedAt"],
        "duration": video["contentDetails"]["duration"],
        "view_count": stats.get("viewCount"),
        "like_count": stats.get("likeCount"),
        "comment_count": stats.get("commentCount"),
        "live_broadcast_content": snippet["liveBroadcastContent"],
    }


def to_channel_row(channel):
    stats = channel["statistics"]
    return {
        "channel_id": channel["id"],
        "title": channel["snippet"]["title"],
        "subscriber_count": stats.get("subscriberCount"),
        "video_count": stats.get("videoCount"),
        "view_count": stats.get("viewCount"),
    }