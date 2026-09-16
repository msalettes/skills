#!/usr/bin/env bash
# Post a ":white_check_mark:" reply on a PR review comment thread.
#
# Usage: post-checkmark-reply.sh <owner> <repo> <pr-number> <root-comment-id>

set -euo pipefail

OWNER="$1"
REPO="$2"
PR="$3"
COMMENT_ID="$4"

gh api "repos/${OWNER}/${REPO}/pulls/${PR}/comments/${COMMENT_ID}/replies" \
  -f body=":white_check_mark:"
