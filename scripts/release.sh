#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
error() { echo -e "${RED}✗ $1${NC}" >&2; exit 1; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
info() { echo -e "${BLUE}ℹ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Parse arguments
if [ -z "$1" ]; then
  error "Usage: ./scripts/release.sh <package>-v<version>

Examples:
  ./scripts/release.sh zema-v0.1.0
  ./scripts/release.sh zema-v0.2.0-dev.1
  ./scripts/release.sh flutter_zema-v0.1.0
  ./scripts/release.sh flutter_zema-v0.1.0-beta.2"
fi

TAG=$1

# Extract package name and version
# Supports: zema-v0.1.0, zema-v0.1.0-dev.1, flutter_zema-v0.1.0
if [[ ! "$TAG" =~ ^([a-z_]+)-v([0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9.]+)?)$ ]]; then
  error "Invalid tag format. Use: <package>-v<version>
  
Examples:
  zema-v0.1.0
  zema-v0.2.0-dev.1
  flutter_zema-v0.1.0-beta.2"
fi

PACKAGE=${BASH_REMATCH[1]}
VERSION=${BASH_REMATCH[2]}

PACKAGE_DIR="packages/$PACKAGE"
PUBSPEC="$PACKAGE_DIR/pubspec.yaml"
CHANGELOG="$PACKAGE_DIR/CHANGELOG.md"

# Check package exists
if [ ! -d "$PACKAGE_DIR" ]; then
  error "Package not found: $PACKAGE_DIR"
fi

echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Release: $PACKAGE v$VERSION"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}\n"

# 1. Check git status
info "Checking git status..."
if [ -n "$(git status --porcelain)" ]; then
  error "Working directory not clean. Commit or stash changes."
fi
success "Working directory clean"

# 2. Run tests
info "Running tests..."
melos test --scope="$PACKAGE" --no-select || error "Tests failed"
success "Tests passed"

# 3. Update pubspec.yaml
info "Updating pubspec.yaml..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/^version: .*/version: $VERSION/" "$PUBSPEC"
else
  sed -i "s/^version: .*/version: $VERSION/" "$PUBSPEC"
fi
success "Version updated to $VERSION"

# 4. Update CHANGELOG (only for non-dev releases)
if [[ ! "$VERSION" =~ -dev\. ]] && [[ ! "$VERSION" =~ -beta\. ]] && [[ ! "$VERSION" =~ -alpha\. ]]; then
  info "Updating CHANGELOG..."
  DATE=$(date +%Y-%m-%d)
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/## \[Unreleased\]/## [Unreleased]\n\n## [$VERSION] - $DATE/" "$CHANGELOG"
  else
    sed -i "s/## \[Unreleased\]/## [Unreleased]\n\n## [$VERSION] - $DATE/" "$CHANGELOG"
  fi
  success "CHANGELOG updated"
else
  info "Skipping CHANGELOG for prerelease"
fi

# 5. Commit and tag
info "Creating commit and tag..."
git add "$PUBSPEC" "$CHANGELOG"
git commit -m "chore($PACKAGE): release v$VERSION" --no-verify

git tag "$TAG" -m "Release $PACKAGE v$VERSION"
success "Created tag: $TAG"

# Done
echo -e "\n${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Release Ready!                                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}\n"

warning "Next steps:"
echo "  1. Push commit: git push origin main"
echo "  2. Push tag: git push origin $TAG"
echo "  3. Publish: cd $PACKAGE_DIR && dart pub publish"