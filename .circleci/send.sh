#!/bin/bash
 
ENVIRON=${ENVIRON:-lab-us-east-1}
TEMPLATE=${TEMPLATE:-partkeepr.nomad.hcl}
SERVICE_NAME=${SERVICE_NAME:-partkeepr}
BUILD_URL=${CIRCLE_BUILD_URL:-}
COUNT=${COUNT:-1}
DOCKER_IMAGE="${DOCKER_IMAGE:-density/partkeepr:0}"
UPSTREAM="${UPSTREAM:-https://partkeepr.density.build}"
 
msg_id=$(uuidgen)
encoded_template=$(base64 "$TEMPLATE")
timestamp=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
 
MSG=$(cat <<EOF
{
  "version": "0",
  "id": "$msg_id",
  "detail-type": "NomadJob",
  "source": "circleci",
  "time": "$timestamp",
  "region": "us-east-1",
  "detail": {
    "build_url": "$BUILD_URL",
    "variables": {
      "count": "$COUNT",
      "docker_image": "$DOCKER_IMAGE",
      "service_name": "$SERVICE_NAME",
      "upstream": "$UPSTREAM"
    },
    "template": "$encoded_template"
  }
}
EOF
   )
which jq && echo $MSG | jq .
MSG=$(echo "$MSG" | tr -d '\n[:space:]')
 
aws sqs send-message \
    --queue-url "https://sqs.us-east-1.amazonaws.com/937369328181/${ENVIRON}-job-queue" \
    --message-body "$MSG"
