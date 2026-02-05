#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Setting up Zema development environment...${NC}\n"

# Check Dart
if ! command -v dart &> /dev/null; then
  echo -e "${RED}Error: Dart SDK not found${NC}"
  exit 1
fi

echo -e "${YELLOW}1. Installing Melos...${NC}"
dart pub global activate melos

echo -e "\n${YELLOW}2. Bootstrapping workspace...${NC}"
melos bootstrap

echo -e "\n${YELLOW}3. Running initial tests...${NC}"
melos test

echo -e "\n${GREEN}✓ Setup complete!${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "  cd packages/zema"
echo "  Start coding!"