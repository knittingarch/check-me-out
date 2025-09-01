#!/bin/bash

# Script to run all code quality checks locally
# Usage: ./check-code.sh

echo "🚀 Running code quality checks..."
echo ""

cd books_api

echo "📋 Installing dependencies..."
bundle install --quiet

echo ""
echo "🧪 Running tests..."
bundle exec rspec --format progress

echo ""
echo "🔍 Running RuboCop linting..."
bundle exec rubocop || echo "⚠️  RuboCop found issues, but continuing..."

echo ""
echo "🛡️  Running security scan..."
bundle exec brakeman --except EOLRails,EOLRuby --no-pager --quiet || echo "⚠️  Brakeman found issues, but continuing..."

echo ""
echo "🔒 Running dependency audit..."
bundle exec bundle audit --update || echo "⚠️  Bundle audit found issues, but continuing..."

echo ""
echo "📊 Running tests with coverage..."
COVERAGE=true bundle exec rspec --format progress

echo ""
echo "✅ Code quality checks completed! Review any warnings above."
