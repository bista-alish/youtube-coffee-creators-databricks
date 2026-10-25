import os
from pathlib import Path

BASE_URL = "https://www.googleapis.com/youtube/v3"
REQUEST_TIMEOUT_SECS = 30

CHANNEL_IDS = [
    "UCMb0O2CdPBNi-QqPk5T3gsQ",  # James Hoffmann
    "UCR2_8uHyWcTSV6iIw6BN4rg",  # Lance Hedrick
    "UCEkuogE57xac9EPZ3EZwWIg",  # Morgan Eckroth
]


PAGE_SIZE = 50
MAX_VIDEOS_PER_CHANNEL = 1000

OUTPUT_DIR = Path(os.getenv("OUTPUT_DIR", Path(__file__).resolve().parent.parent / "output"))
CHANNEL_FOLDER = "channel_snapshots"
VIDEO_FOLDER = "video_snapshots"