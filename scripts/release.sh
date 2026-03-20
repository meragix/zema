#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
error()   { echo -e "${RED}✗ $1${NC}" >&2; exit 1; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
info()    { echo -e "${BLUE}ℹ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

USAGE="Usage:
  ./scripts/release.sh <package>-<version>     # single package
  ./scripts/release.sh --all <version>         # all packages

Examples:
  ./scripts/release.sh zema-0.5.0
  ./scripts/release.sh zema-0.2.0-dev.1
  ./scripts/release.sh --all 0.5.0"

VERSION_RE='^[0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9.]+)?$'
IS_PRERELEASE=false
PACKAGES=()
TAGS=()

# --------------------------------------------------------------------------- #
# Parse arguments
# --------------------------------------------------------------------------- #

if [ -z "$1" ]; then
  error "$USAGE"
fi

if [ "$1" = "--all" ]; then
  [ -z "$2" ] && error "$USAGE"
  VERSION="$2"
  [[ "$VERSION" =~ $VERSION_RE ]] || error "Invalid version: $VERSION"
  for dir in packages/*/; do
    PACKAGES+=("$(basename "$dir")")
  done
else
  TAG="$1"
  [[ "$TAG" =~ ^([a-z_]+)-([0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9.]+)?)$ ]] \
    || error "Invalid tag format.\n\n$USAGE"
  PACKAGES=("${BASH_REMATCH[1]}")
  VERSION="${BASH_REMATCH[2]}"
fi

[[ "$VERSION" =~ -(dev|beta|alpha)\. ]] && IS_PRERELEASE=true

# --------------------------------------------------------------------------- #
# Pre-flight checks
# --------------------------------------------------------------------------- #

for PKG in "${PACKAGES[@]}"; do
  [ -d "packages/$PKG" ] || error "Package not found: packages/$PKG"
done

echo -e "\n${GREEN}╔════════════════════════════════════════════════╗${NC}"
if [ ${#PACKAGES[@]} -eq 1 ]; then
  echo -e "${GREEN}║  Release: ${PACKAGES[0]} v$VERSION"
else
  echo -e "${GREEN}║  Release: ${#PACKAGES[@]} packages → v$VERSION"
fi
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}\n"

info "Checking git status..."
if [ -n "$(git status --porcelain)" ]; then
  error "Working directory not clean. Commit or stash changes first."
fi
success "Working directory clean"

info "Running tests..."
melos test --no-select || error "Tests failed"
success "All tests passed"

# --------------------------------------------------------------------------- #
# Update each package
# --------------------------------------------------------------------------- #

CHANGED_FILES=()
DATE=$(date +%Y-%m-%d)

for PKG in "${PACKAGES[@]}"; do
  PUBSPEC="packages/$PKG/pubspec.yaml"
  CHANGELOG="packages/$PKG/CHANGELOG.md"

  info "[$PKG] Updating pubspec.yaml → $VERSION"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/^version: .*/version: $VERSION/" "$PUBSPEC"
  else
    sed -i "s/^version: .*/version: $VERSION/" "$PUBSPEC"
  fi
  CHANGED_FILES+=("$PUBSPEC")

  if $IS_PRERELEASE; then
    info "[$PKG] Skipping CHANGELOG for prerelease"
  else
    if grep -q '## \[Unreleased\]' "$CHANGELOG" 2>/dev/null; then
      info "[$PKG] Updating CHANGELOG"
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/## \[Unreleased\]/## [Unreleased]\n\n## [$VERSION] - $DATE/" "$CHANGELOG"
      else
        sed -i "s/## \[Unreleased\]/## [Unreleased]\n\n## [$VERSION] - $DATE/" "$CHANGELOG"
      fi
      CHANGED_FILES+=("$CHANGELOG")
    else
      warning "[$PKG] No [Unreleased] section in CHANGELOG — skipping"
    fi
  fi

  TAGS+=("$PKG-$VERSION")
done

# --------------------------------------------------------------------------- #
# Commit and tag
# --------------------------------------------------------------------------- #

info "Creating release commit..."
git add "${CHANGED_FILES[@]}"

if [ ${#PACKAGES[@]} -eq 1 ]; then
  git commit -m "chore(${PACKAGES[0]}): release v$VERSION"
else
  PKGS_LIST=$(IFS=', '; echo "${PACKAGES[*]}")
  git commit -m "chore: release v$VERSION ($PKGS_LIST)"
fi

for TAG in "${TAGS[@]}"; do
  PKG="${TAG%-*}"  # strip -<version> suffix
  git tag "$TAG" -m "Release $PKG v$VERSION"
  success "Created tag: $TAG"
done

# --------------------------------------------------------------------------- #
# Next steps
# --------------------------------------------------------------------------- #

echo -e "\n${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Release Ready!                                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}\n"

warning "Next steps:"
echo "  1. Push commit:  git push origin main"

if [ ${#TAGS[@]} -eq 1 ]; then
  echo "  2. Push tag:     git push origin ${TAGS[0]}"
  echo "  3. Publish:      cd packages/${PACKAGES[0]} && dart pub publish"
else
  TAGS_STR=$(IFS=' '; echo "${TAGS[*]}")
  echo "  2. Push tags:    git push origin $TAGS_STR"
  echo "  3. Publish each:"
  for PKG in "${PACKAGES[@]}"; do
    echo "       cd packages/$PKG && dart pub publish"
  done
fi
echo ""
