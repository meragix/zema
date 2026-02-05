.PHONY: setup bootstrap test analyze format clean

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

# All checks (CI simulation)
ci: format-check analyze test

# Help
help:
	@echo "Available commands:"
	@echo "  make setup         - Setup development environment"
	@echo "  make bootstrap     - Bootstrap workspace"
	@echo "  make test          - Run tests"
	@echo "  make analyze       - Run static analysis"
	@echo "  make format        - Format code"
	@echo "  make clean         - Clean workspace"
	@echo "  make ci            - Run all CI checks"