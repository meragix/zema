.PHONY: setup bootstrap test analyze format clean snippets snippets-docs bench ci help

# Setup development environment
setup:
	dart pub global activate melos
	melos bootstrap

# Bootstrap workspace
bootstrap:
	melos bootstrap

# Run tests
test:
	melos test

# Run tests with coverage
test-coverage:
	melos test:coverage

# Analyze code
analyze:
	melos analyze

# Format code
format:
	melos format

# Check formatting
format-check:
	melos format:check

# Clean
clean:
	melos clean
	find . -name "pubspec.lock" -delete
	find . -name ".dart_tool" -type d -exec rm -rf {} +

# Publish check
publish-check:
	melos publish:check

# Version bump
version:
	melos version

# Run competitive benchmarks (zema vs acanthis, ez_validator, luthor, zod_validation, zard)
bench:
	cd benchmark && dart pub get && dart run bin/competitive.dart

# Compile every dart snippet of the READMEs and pub.dev examples
snippets:
	dart run scripts/check_snippets.dart --readmes

# Report snippet errors in the docs site pages
snippets-docs:
	dart run scripts/check_snippets.dart docs/

# All checks (CI simulation)
ci: format-check analyze test snippets

# Help
help:
	@echo "Available commands:"
	@echo "  make setup         - Setup development environment"
	@echo "  make bootstrap     - Bootstrap workspace"
	@echo "  make test          - Run tests"
	@echo "  make analyze       - Run static analysis"
	@echo "  make format        - Format code"
	@echo "  make clean         - Clean workspace"
	@echo "  make snippets      - Compile README and example snippets"
	@echo "  make ci            - Run all CI checks"
	@echo "  make bench         - Run competitive benchmarks"