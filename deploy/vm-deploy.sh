#!/usr/bin/env bash
# Deploys the dev branch to the VM in seconds: instead of building OpenProject from
# source, it layers the files dev changed since BASE_TAG onto the stock image.
# Migrations in db/migrate run on container start, as with the stock image.
#
# One-time setup on the VM:
#   git clone --filter=blob:none -b dev https://github.com/Joatani/ticketing-base.git ~/ticketing/src
#   in ~/ticketing/docker-compose.yml: image: ticketing-openproject:current
# Rollback:
#   docker tag ticketing-openproject:previous ticketing-openproject:current
#   docker compose -f ~/ticketing/docker-compose.yml up -d openproject
set -euo pipefail

BASE_TAG=17.9.3 # upstream release dev is built on; bump it with every upstream merge
BRANCH=dev
IMAGE=ticketing-openproject
ROOT=$HOME/ticketing
SRC=$ROOT/src
BUILD=$ROOT/build
OVERLAY_PATHS=(. ':!.github' ':!deploy' ':!docs' ':!spec')

main() {
  exec 9>"$ROOT/.deploy.lock"
  flock 9

  git -C "$SRC" fetch -q --tags origin "$BRANCH"
  git -C "$SRC" checkout -q --detach "origin/$BRANCH"

  rm -rf "$BUILD"
  mkdir -p "$BUILD/overlay"
  cp "$SRC/deploy/Dockerfile" "$BUILD/"
  # --no-renames so a renamed file also removes its old path
  git -C "$SRC" diff --no-renames --name-only --diff-filter=d "v$BASE_TAG" HEAD -- "${OVERLAY_PATHS[@]}" > "$BUILD/changed.txt"
  git -C "$SRC" diff --no-renames --name-only --diff-filter=D "v$BASE_TAG" HEAD -- "${OVERLAY_PATHS[@]}" > "$BUILD/deleted.txt"

  # shortcut: the overlay carries Ruby, ERB, YAML and migrations only; frontend, asset
  # and gem changes need the full docker/prod/Dockerfile build. Add that path when dev first needs one.
  if grep -E '(^|/)(frontend|app/assets)/|(^|/)Gemfile|\.gemspec$|^package(-lock)?\.json$|(^|/)js-[^/]*\.yml$' \
      "$BUILD/changed.txt" "$BUILD/deleted.txt"; then
    echo "^ these changes need a full image build; the overlay deploy cannot ship them" >&2
    exit 1
  fi
  (cd "$SRC" && xargs -r -d '\n' cp --parents -t "$BUILD/overlay" < "$BUILD/changed.txt")

  local sha
  sha=$(git -C "$SRC" rev-parse --short HEAD)
  docker build -q --build-arg BASE_TAG="$BASE_TAG" -t "$IMAGE:$sha" "$BUILD"
  if docker image inspect "$IMAGE:current" > /dev/null 2>&1; then
    docker tag "$IMAGE:current" "$IMAGE:previous"
  fi
  docker tag "$IMAGE:$sha" "$IMAGE:current"
  docker compose -f "$ROOT/docker-compose.yml" up -d openproject
  echo "Deployed $sha ($(wc -l < "$BUILD/changed.txt") changed, $(wc -l < "$BUILD/deleted.txt") deleted files over $BASE_TAG)"
}

# main runs from one fully parsed line, so the checkout above can safely replace this file
main "$@"; exit
