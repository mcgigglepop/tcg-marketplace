#!/bin/bash

set -euo pipefail

if [ -f .env ]; then
  echo "Loading environment variables from .env"
  set -a
  source .env
  set +a
fi

GO_BUILD_OUTPUT="tcg-marketplace-build"
CACHE_FLAG=${CACHE_FLAG:-false}
PRODUCTION_FLAG=${PRODUCTION_FLAG:-false}
COGNITO_USER_POOL_ID=${COGNITO_USER_POOL_ID:?Missing COGNITO_USER_POOL_ID}
COGNITO_CLIENT_ID=${COGNITO_CLIENT_ID:?Missing COGNITO_CLIENT_ID}

if [ ! -d "cmd/web" ]; then
  echo "Error: script must be run from repo root or server directory" >&2
  exit 1
fi

go build -o "${GO_BUILD_OUTPUT}" ./cmd/web && \
"./${GO_BUILD_OUTPUT}" \
  -cache=${CACHE_FLAG} \
  -production=${PRODUCTION_FLAG} \
  -cognito-user-pool-id=${COGNITO_USER_POOL_ID} \
  -cognito-client-id=${COGNITO_CLIENT_ID}
