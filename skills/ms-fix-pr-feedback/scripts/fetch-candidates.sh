#!/usr/bin/env bash
# Fetch review threads for a PR and filter down to the ones eligible for auto-fix.
#
# Usage: fetch-candidates.sh <owner> <repo> <pr-number>
#
# A thread qualifies (is printed) only if ALL of:
#   1. isResolved is false
#   2. no reply body contains checkmark
#   3. root comment author != PR author
#   4. root comment has a "+1" reaction from the authenticated user
#
# Output: a JSON array on stdout, one object per qualifying thread:
#   { thread_id, comment_id, path, diff_hunk, body, url, replies: [{author, body}] }

set -euo pipefail

OWNER="$1"
REPO="$2"
PR="$3"

ME=$(gh api user -q .login)
PR_AUTHOR=$(gh api "repos/${OWNER}/${REPO}/pulls/${PR}" -q .user.login)

has_checkmark() {
  # $1 = comment body text
  local body="$1"
  if [[ "$body" == *"✅"* ]] || [[ "$body" == *":white_check_mark:"* ]]; then
    return 0
  fi
  return 1
}

has_my_thumbsup() {
  # $1 = review comment databaseId (REST comment id, not the GraphQL thread id)
  local comment_id="$1"
  gh api "repos/${OWNER}/${REPO}/pulls/comments/${comment_id}/reactions" --jq \
    "[.[] | select(.content == \"+1\" and .user.login == \"${ME}\")] | length > 0" 2>/dev/null || echo "false"
}

ALL_THREADS='[]'
AFTER='null'
while :; do
  PAGE=$(gh api graphql -f query='
    query($owner:String!, $repo:String!, $pr:Int!, $after:String) {
      repository(owner:$owner, name:$repo) {
        pullRequest(number:$pr) {
          reviewThreads(first:100, after:$after) {
            pageInfo { hasNextPage endCursor }
            nodes {
              id
              isResolved
              comments(first:50) {
                nodes {
                  databaseId
                  author { login }
                  body
                  path
                  diffHunk
                  url
                  replyTo { id }
                }
              }
            }
          }
        }
      }
    }' -f owner="$OWNER" -f repo="$REPO" -F pr="$PR" -f after="$AFTER")

  THREADS=$(echo "$PAGE" | jq '.data.repository.pullRequest.reviewThreads.nodes')
  ALL_THREADS=$(jq -n --argjson a "$ALL_THREADS" --argjson b "$THREADS" '$a + $b')

  HAS_NEXT=$(echo "$PAGE" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage')
  if [[ "$HAS_NEXT" != "true" ]]; then
    break
  fi
  AFTER=$(echo "$PAGE" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor')
  AFTER="\"$AFTER\""
done

OUT_FILE=$(mktemp)
trap 'rm -f "$OUT_FILE"' EXIT

echo "$ALL_THREADS" | jq -c '.[]' | while read -r thread; do
  IS_RESOLVED=$(echo "$thread" | jq -r '.isResolved')
  if [[ "$IS_RESOLVED" == "true" ]]; then
    continue
  fi

  ROOT=$(echo "$thread" | jq -c '[.comments.nodes[] | select(.replyTo == null)][0]')
  if [[ "$ROOT" == "null" ]]; then
    continue
  fi

  ROOT_AUTHOR=$(echo "$ROOT" | jq -r '.author.login')
  if [[ "$ROOT_AUTHOR" == "$PR_AUTHOR" ]]; then
    continue
  fi

  REPLIES=$(echo "$thread" | jq -c '[.comments.nodes[] | select(.replyTo != null) | {author: .author.login, body: .body}]')
  ANY_CHECKMARK="false"
  while read -r reply_body; do
    if has_checkmark "$reply_body"; then
      ANY_CHECKMARK="true"
      break
    fi
  done < <(echo "$REPLIES" | jq -r '.[].body')
  if [[ "$ANY_CHECKMARK" == "true" ]]; then
    continue
  fi

  COMMENT_ID=$(echo "$ROOT" | jq -r '.databaseId')
  THUMBSUP=$(has_my_thumbsup "$COMMENT_ID")
  if [[ "$THUMBSUP" != "true" ]]; then
    continue
  fi

  ITEM=$(jq -n \
    --arg thread_id "$(echo "$thread" | jq -r '.id')" \
    --arg comment_id "$COMMENT_ID" \
    --arg path "$(echo "$ROOT" | jq -r '.path')" \
    --arg diff_hunk "$(echo "$ROOT" | jq -r '.diffHunk')" \
    --arg body "$(echo "$ROOT" | jq -r '.body')" \
    --arg url "$(echo "$ROOT" | jq -r '.url')" \
    --argjson replies "$REPLIES" \
    '{thread_id: $thread_id, comment_id: ($comment_id | tonumber), path: $path, diff_hunk: $diff_hunk, body: $body, url: $url, replies: $replies}')

  echo "$ITEM" >> "$OUT_FILE"
done

if [[ -s "$OUT_FILE" ]]; then
  jq -s '.' "$OUT_FILE"
else
  echo '[]'
fi
