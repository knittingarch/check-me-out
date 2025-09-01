# Books API

A Ruby on Rails API for managing a library book collection with borrowing and reservation functionality.

## Overview

This API provides endpoints for managing books and authors in a library system. It supports book searching, filtering, sorting, pagination, and basic library operations like borrowing and returning books.

## Features

- **Book Management**: Create, read, update, and delete books
- **Author Management**: Books can have multiple authors
- **Search & Filter**: Search books by title, author, or ISBN
- **Book Status**: Track availability (available, borrowed, reserved)
- **Borrowing System**: Reserve and borrow books with due dates
- **Pagination**: Paginated results for large datasets
- **Sorting**: Sort results by various fields

## Technical Stack

- **Ruby**: 3.3.6
- **Rails**: 7.1.0
- **Database**: PostgreSQL
- **Testing**: RSpec with FactoryBot
- **Code Quality**: RuboCop, Brakeman, Bullet

## Setup

### Prerequisites

- Ruby 3.3.6
- PostgreSQL
- Bundler

### Installation

1. Clone the repository and navigate to the books_api directory
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Configure environment variables:
   ```bash
   # Copy and edit the environment file
   cp .env.example .env
   # Set your PostgreSQL credentials:
   # PGUSER=your_db_user
   # PGPASSWORD=your_db_password
   # PGHOST=localhost
   ```

4. Set up the database:
   ```bash
   bundle exec rails db:create
   bundle exec rails db:migrate
   bundle exec rails db:seed
   ```

### Running the Application

Start the Rails server:
```bash
bundle exec rails server -p 3000
```

The API will be available at `http://localhost:3000`

## API Endpoints

### Books

- `GET /books` - List all books
- `GET /books/:id` - Get a specific book
- `POST /books` - Create a new book
- `PUT /books/:id` - Update a book
- `DELETE /books/:id` - Delete a book
- `GET /books/search` - Search and filter books

### Search Parameters

The `/books/search` endpoint supports:

**Filters** (at least one required):
- `filter[q]` - General search across title, author, and ISBN
- `filter[title]` - Filter by book title
- `filter[author]` - Filter by author name
- `filter[isbn]` - Filter by ISBN
- `filter[status]` - Filter by status (available, borrowed, reserved)
- `filter[borrowed_until]` - Filter by due date (YYYY-MM-DD)

**Sorting**:
- `sort` - Sort by fields: title, author, isbn, published_date, status, borrowed_until
- Use `-` prefix for descending order (e.g., `sort=-title`)
- Multiple fields: `sort=author,title`

**Pagination**:
- `page` - Page number (default: 1)
- `per_page` - Items per page (1-100, default: 20)

### Example Requests

```bash
# Search for books with "ruby" in title, author, or ISBN
curl "http://localhost:3001/books/search?filter[q]=ruby"

# Filter by author and sort by title
curl "http://localhost:3001/books/search?filter[author]=Doe&sort=title"

# Available books, sorted by publication date, page 2
curl "http://localhost:3001/books/search?filter[status]=available&sort=-published_date&page=2"
```

## Models

### Book
- Has many authors (many-to-many relationship)
- Attributes: title, isbn, published_date, status, borrowed_until
- Status: available, borrowed, reserved
- Methods: reserve, borrow, return, cancel_reservation

### Author
- Has many books (many-to-many relationship)
- Attributes: name

## Testing

Run the test suite:
```bash
# All tests
bundle exec rspec

# Specific test file
bundle exec rspec spec/requests/books_spec.rb

# Specific test within a test file
bundle exec rspec spec/requests/books_spec.rb:109

# With documentation format
bundle exec rspec --format documentation
```

### Test Coverage

- Model validations and associations
- Controller endpoints and error handling
- Search functionality and edge cases
- Pagination and sorting

## Development Tools

- **RSpec**: Testing framework
- **FactoryBot**: Test data generation
- **Faker**: Fake data generation
- **RuboCop**: Ruby style guide enforcement
- **Brakeman**: Security vulnerability scanner
- **Bullet**: N+1 query detection
- **SimpleCov**: Test coverage reporting

## Code Quality

Run code quality checks:
```bash
# Style guide compliance
bundle exec rubocop

# Security vulnerabilities
bundle exec brakeman

# Dependency vulnerabilities
bundle exec bundle-audit
```

## Database Schema

The application uses PostgreSQL with the following main tables:
- `books` - Book records
- `authors` - Author records
- `authors_books` - Join table for many-to-many relationship

## Contributing

1. Run tests: `bundle exec rspec`
2. Check code style: `bundle exec rubocop`
3. Check security: `bundle exec brakeman`
4. Ensure test coverage is maintained
