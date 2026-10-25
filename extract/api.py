import logging
import os

import requests
from tenacity import before_sleep_log, retry, retry_if_exception, stop_after_attempt, wait_exponential

from config import BASE_URL, REQUEST_TIMEOUT_SECS

logger = logging.getLogger(__name__)

TRANSIENT_STATUSES = {429, 500, 502, 503, 504}
RATE_LIMIT_REASONS = {"rateLimitExceeded", "userRateLimitExceeded"}


def error_reason(error):
    try:
        return error.response.json()["error"]["errors"][0]["reason"]
    except (ValueError, KeyError, IndexError):
        return "unknown"


def is_transient(error):
    if isinstance(error, (requests.ConnectionError, requests.Timeout)):
        return True
    if isinstance(error, requests.HTTPError):
        status = error.response.status_code
        return status in TRANSIENT_STATUSES or error_reason(error) in RATE_LIMIT_REASONS
    return False


@retry(
    stop=stop_after_attempt(5),
    wait=wait_exponential(multiplier=1, max=30),
    retry=retry_if_exception(is_transient),
    before_sleep=before_sleep_log(logger, logging.WARNING),
    reraise=True,
)
def get_json(endpoint, params):
    response = requests.get(
        f"{BASE_URL}/{endpoint}",
        params=params,
        headers={"X-Goog-Api-Key": os.environ["YOUTUBE_API_KEY"]},
        timeout=REQUEST_TIMEOUT_SECS,
    )
    response.raise_for_status()
    return response.json()