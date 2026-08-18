#!/usr/bin/env bash
# Local Postgres for development. Docker owns the container; it runs detached with
# host networking because bridge networking is unavailable in the sandbox.
# Sourced by .niteshift/setup and .niteshift/resume.

DB_CONTAINER=umami-db
DB_IMAGE=postgres:15-alpine

ensure_postgres() {
  if [ -z "$(docker ps -aq -f "name=^${DB_CONTAINER}$")" ]; then
    docker run -d \
      --name "$DB_CONTAINER" \
      --network=host \
      --restart unless-stopped \
      -e POSTGRES_DB=umami \
      -e POSTGRES_USER=umami \
      -e POSTGRES_PASSWORD=umami \
      -v umami-db-data:/var/lib/postgresql/data \
      "$DB_IMAGE" >/dev/null
  elif [ -z "$(docker ps -q -f "name=^${DB_CONTAINER}$")" ]; then
    docker start "$DB_CONTAINER" >/dev/null
  fi

  for _ in $(seq 1 60); do
    if docker exec "$DB_CONTAINER" pg_isready -U umami -d umami >/dev/null 2>&1; then
      echo "postgres is ready on localhost:5432"
      return 0
    fi
    sleep 1
  done

  echo "postgres did not become ready" >&2
  docker logs --tail 50 "$DB_CONTAINER" >&2 || true
  return 1
}
