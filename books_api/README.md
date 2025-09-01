# Books API

A Ruby on Rails API for managing a library book collection with borrowing and reservation functionality.

## Overview

This API provides endpoints for managing books and authors in a library system. It supports book searching, filtering, sorting, pagination, and basic library operations like borrowing and returning books.

## Features

- **Book Management**: Create, read, update, and delete books
- **Author Management**: Books can have multiple authors
- **Multiple Copies**: Support for multiple copies of the same book
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

# Find available copies of a specific book by ISBN
curl "http://localhost:3001/books/search?filter[isbn]=9781234567890&filter[status]=available"
```

### Example Response (Multiple Copies)

When searching for books, you'll see multiple copies with the same ISBN but different copy numbers:

```json
{
  "books": [
    {
      "id": 1,
      "title": "The Hobbit",
      "isbn": "9780547928227",
      "copy_number": 1,
      "status": "available",
      "borrowed_until": null,
      "published_date": "1937-09-21",
      "authors": [
        {"id": 1, "name": "J.R.R. Tolkien"}
      ]
    },
    {
      "id": 2,
      "title": "The Hobbit",
      "isbn": "9780547928227",
      "copy_number": 2,
      "status": "borrowed",
      "borrowed_until": "2025-09-08",
      "published_date": "1937-09-21",
      "authors": [
        {"id": 1, "name": "J.R.R. Tolkien"}
      ]
    },
    {
      "id": 3,
      "title": "The Hobbit",
      "isbn": "9780547928227",
      "copy_number": 3,
      "status": "reserved",
      "borrowed_until": "2025-09-02",
      "published_date": "1937-09-21",
      "authors": [
        {"id": 1, "name": "J.R.R. Tolkien"}
      ]
    }
  ],
  "pagination": {
    "current_page": 1,
    "per_page": 20,
    "total_pages": 1,
    "total_count": 3
  }
}
```

## Models

### Book
- Has many authors (many-to-many relationship)
- Attributes: title, isbn, published_date, status, borrowed_until, copy_number
- Status: available, borrowed, reserved
- Copy System: Multiple copies of the same book share the same ISBN but have unique copy numbers
- Methods: reserve, borrow, return, cancel_reservation

### Author
- Has many books (many-to-many relationship)
- Attributes: name

## Multiple Copies System

The API supports multiple copies of the same book with the following features:

### Copy Management
- **Unique Copy Numbers**: Each book instance has an automatically assigned `copy_number`
- **Shared Metadata**: Books with the same ISBN share title, authors, and publication information
- **Individual Status**: Each copy can have its own status (available, borrowed, reserved)
- **Individual Due Dates**: Each copy can have different borrowing/return dates

### How It Works
1. **Automatic Copy Numbering**: When creating books with the same ISBN, copy numbers are automatically assigned (1, 2, 3, etc.)
2. **Independent Tracking**: Each copy is tracked separately in the database
3. **Search Results**: Search results include all copies, with copy numbers displayed
4. **Availability**: The system can show which specific copies are available for borrowing

### Database Implementation
- Each book record represents one physical copy
- Copy numbers are automatically generated based on existing books with the same ISBN
- Books with the same ISBN will have copy_number values: 1, 2, 3, etc.

### API Behavior
- All endpoints work with individual copies (each copy has its own ID)
- Search results will return all copies of matching books
- Copy information is included in book responses
- Filter by status to find available copies of popular books

### Example Seed Data
The seed file creates multiple copies of popular books to demonstrate this functionality:
- Popular titles get 2-4 additional copies
- Each copy has its own status (available, borrowed, or reserved)
- Copy numbers are automatically assigned

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
- `books` - Book records (each record represents one physical copy)
- `authors` - Author records
- `authors_books` - Join table for many-to-many relationship

### Key Fields
- `books.copy_number` - Automatically assigned number for books with the same ISBN
- `books.isbn` - Shared identifier for all copies of the same book
- `books.status` - Individual status per copy (available, borrowed, reserved)
- `books.borrowed_until` - Individual due date per copy

## Background Jobs & Automation

### Expired Books Job

The application includes an automated job system to handle overdue books and reservations:

#### ExpiredBooksJob

**Purpose**: Automatically expires books that have reached the end of their borrowing/reservation period.

**What it does**:
- Finds all books with status `borrowed` or `reserved` where `borrowed_until` date has passed
- Calls `book.return` on each overdue book to change status to `available`
- Logs detailed information about the process
- Returns the count of books that were expired

**Implementation**:
```ruby
# Run the job immediately
ExpiredBooksJob.perform_now

# Queue the job for background processing
ExpiredBooksJob.perform_later
```

### Rake Tasks

Several rake tasks are available for managing expired books:

#### books:expire_overdue
Runs the ExpiredBooksJob and provides detailed output:
```bash
rails books:expire_overdue
```

**Output includes**:
- List of books to be expired (before processing)
- Job execution timestamps
- Total count of books expired

#### books:show_overdue
Shows all currently overdue books and reservations (dry run):
```bash
rails books:show_overdue
```

**Output includes**:
- All overdue borrowed books and reservations
- Due dates and book details
- Breakdown by status (borrowed vs reserved)

#### books:create_expired_test_data
Creates test data with overdue books for development/testing:
```bash
rails books:create_expired_test_data
```

**⚠️ Development only** - Creates sample overdue books for testing the expiration system.

### Automated Scheduling

#### Cron Job Setup

The expired books job is configured to run automatically every day at 1:00 AM using a cron job.

**Cron Configuration**:
```bash
0 1 * * * /path/to/expire_books_cron.sh >> /path/to/expired_books_cron.log 2>&1
```

**Shell Script** (`expire_books_cron.sh`):
```bash
#!/bin/bash

# Set PATH to include your Ruby installation
export PATH="/path/to/ruby/bin:$PATH"

# Change to the Rails app directory
cd /path/to/your/books_api

# Run the expired books job
bundle exec rails books:expire_overdue RAILS_ENV=production
```

#### Monitoring

**Check cron job logs**:
```bash
# View recent cron job output
cat /path/to/expired_books_cron.log

# View last 10 lines
tail /path/to/expired_books_cron.log

# Monitor live (follow new entries)
tail -f /path/to/expired_books_cron.log
```

**Verify cron job is scheduled**:
```bash
crontab -l
```

**Test the job manually**:
```bash
# Run the shell script directly
./expire_books_cron.sh

# Or run the rake task
rails books:expire_overdue
```

#### Job Workflow

1. **Daily at 1:00 AM**: Cron triggers the shell script
2. **Environment Setup**: Script sets up Ruby/Rails environment
3. **Job Execution**: ExpiredBooksJob processes overdue books
4. **Logging**: Results are logged to both Rails logs and cron log file
5. **Completion**: Books are returned to available status

**Example Log Output**:
```
Starting expired books job at 2025-09-01 16:40:05 UTC

Books to be expired:
- I Sing the Body Electric (ID: 29) - Status: Borrowed
- A Swiftly Tilting Planet (ID: 30) - Status: Reserved

Expired books job completed at 2025-09-01 16:40:05 UTC
Total books expired: 2
```

### Development & Testing

**Create test scenario**:
```bash
# Create overdue books
rails books:create_expired_test_data

# Check what would be expired
rails books:show_overdue

# Run the expiration job
rails books:expire_overdue

# Verify no overdue books remain
rails books:show_overdue
```

## Contributing

1. Run tests: `bundle exec rspec`
2. Check code style: `bundle exec rubocop`
3. Check security: `bundle exec brakeman`
4. Ensure test coverage is maintained
