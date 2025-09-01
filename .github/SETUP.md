# GitHub Actions CI/CD Setup

This repository includes comprehensive GitHub Actions workflows to ensure code quality before merging.

## Workflows Included

### 1. CI Workflow (`.github/workflows/ci.yml`)
- **Tests**: Runs RSpec test suite with PostgreSQL database
- **Linting**: Runs RuboCop for code style enforcement
- **Security**: Runs Brakeman security scanner and Bundler Audit

### 2. Code Coverage (`.github/workflows/coverage.yml`)
- Generates code coverage reports using SimpleCov
- Enforces minimum coverage threshold (80%)
- Uploads coverage artifacts

### 3. PR Checks (`.github/workflows/pr-checks.yml`)
- Validates PR requirements
- Checks for test files in PRs
- Validates commit message format (conventional commits)

## Setting Up Branch Protection

To ensure these checks run before merging, set up branch protection rules:

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Branches**
3. Click **Add rule** for your main branch
4. Configure the following settings:

### Required Settings:
- ✅ **Require a pull request before merging**
- ✅ **Require status checks to pass before merging**
  - Select these required checks:
    - `test` (from CI workflow)
    - `lint` (from CI workflow)
    - `security` (from CI workflow)
    - `coverage` (from coverage workflow)
- ✅ **Require up-to-date branches before merging**
- ✅ **Require conversation resolution before merging**

### Optional but Recommended:
- ✅ **Restrict pushes that create files**
- ✅ **Require linear history**
- ✅ **Include administrators** (applies rules to repo admins too)

## Local Development Setup

Install the required gems for local testing:

```bash
cd books_api
bundle install
```

### Run checks locally:

```bash
# Run tests
bundle exec rspec

# Run linting
bundle exec rubocop

# Run security scan
bundle exec brakeman

# Run dependency audit
bundle exec bundle audit

# Run tests with coverage
COVERAGE=true bundle exec rspec
```

### Auto-fix linting issues:
```bash
bundle exec rubocop --auto-correct
```

## Code Quality Standards

### RuboCop Configuration
- Located in `books_api/.rubocop.yml`
- Configured for Rails API projects
- Includes RSpec-specific rules
- Max line length: 120 characters
- Method length limit: 15 lines (excluding specs)

### Test Coverage
- Minimum coverage: 80%
- Coverage reports generated in `coverage/` directory
- Excludes spec files, config, and vendor directories

### Security Scanning
- **Brakeman**: Static analysis for Rails security vulnerabilities
- **Bundler Audit**: Checks for vulnerable gem versions

## Commit Message Format

Use conventional commit format for better tracking:
- `feat: add new feature`
- `fix: resolve bug`
- `docs: update documentation`
- `style: formatting changes`
- `refactor: code refactoring`
- `test: add or update tests`
- `chore: maintenance tasks`

## Troubleshooting

### Common Issues:

1. **Tests failing locally but passing in CI**
   - Ensure your local database is set up correctly
   - Run `bundle exec rails db:test:prepare`

2. **RuboCop violations**
   - Run `bundle exec rubocop --auto-correct` to fix automatically
   - Review `.rubocop.yml` for custom rules

3. **Security warnings**
   - Update vulnerable gems: `bundle update`
   - Review Brakeman warnings and address accordingly

### Skipping Checks (Use Sparingly)
If you need to bypass checks in emergency situations:
- Add `[skip ci]` to commit message to skip all CI
- Use `rubocop:disable` comments for specific linting issues
- Address security warnings or add them to ignore list if false positives

## Continuous Improvement

Consider adding these additional checks:
- Database migration safety checks
- Performance regression testing
- Accessibility testing
- API documentation validation
- Dependency license checking
