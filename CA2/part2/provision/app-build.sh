#!/usr/bin/env bash
# app VM: clones the repository and builds the Bookstore (runs as the vagrant user). Idempotent.
set -euo pipefail

CLONE_REPO="${CLONE_REPO:-true}"
BUILD_APPS="${BUILD_APPS:-true}"
REPO_BRANCH="${REPO_BRANCH:-main}"
REPO_DIR="$HOME/cogsi"

if [ "$CLONE_REPO" = "true" ]; then
  if [ -d "$REPO_DIR/.git" ]; then
    echo "[app-build] Repositorio ja existe - a atualizar"
    git -C "$REPO_DIR" fetch --quiet origin
    git -C "$REPO_DIR" checkout --quiet "$REPO_BRANCH"
    git -C "$REPO_DIR" pull --ff-only --quiet origin "$REPO_BRANCH"
  else
    echo "[app-build] A clonar o repositorio (branch $REPO_BRANCH)"
    git clone --quiet --branch "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"
  fi
else
  echo "[app-build] CLONE_REPO=false - clone ignorado"
fi

if [ "$BUILD_APPS" = "true" ]; then
  if [ ! -d "$REPO_DIR" ]; then
    echo "[app-build] ERRO: $REPO_DIR nao existe. Corre com CLONE_REPO=true." >&2
    exit 1
  fi
  echo "[app-build] Build do Bookstore"
  (cd "$REPO_DIR/CA1/part2" && ./gradlew clean build --no-daemon --console=plain)
else
  echo "[app-build] BUILD_APPS=false - build ignorado"
fi
