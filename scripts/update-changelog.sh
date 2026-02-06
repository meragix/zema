#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$1" ]; then
  echo -e "${YELLOW}Usage: ./scripts/update-changelog.sh <version>${NC}"
  echo "Example: ./scripts/update-changelog.sh 0.2.0"
  exit 1
fi

VERSION=$1
DATE=$(date +%Y-%m-%d)

echo -e "${GREEN}Updating CHANGELOG for version $VERSION...${NC}\n"

# Update package CHANGELOG
cd packages/zema

# Replace [Unreleased] with version
sed -i '' "s/## \[Unreleased\]/## [Unreleased]\n\n## [$VERSION] - $DATE/" CHANGELOG.md

# Update links at bottom
echo "" >> CHANGELOG.md
echo "[$VERSION]: https://github.com/meragix/zema/compare/v$(git describe --tags --abbrev=0)...v$VERSION" >> CHANGELOG.md

echo -e "${GREEN}✓ CHANGELOG updated!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review CHANGELOG.md"
echo "  2. Commit changes"
echo "  3. Create release tag: git tag v$VERSION"