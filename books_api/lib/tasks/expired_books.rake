namespace :books do
  desc "Expire overdue borrowed books and reservations"
  task expire_overdue: :environment do
    puts "Starting expired books job at #{Time.current}"

    # Show what will be processed before running the job
    overdue_books = Book.where(status: [:borrowed, :reserved])
                       .where('borrowed_until < ?', Time.current)

    if overdue_books.any?
      puts "\nBooks to be expired:"
      overdue_books.each do |book|
        puts "- #{book.title} (ID: #{book.id}) - Status: #{book.status.capitalize}"
      end
      puts ""
    end

    # Run the job and capture the result
    result = ExpiredBooksJob.perform_now

    puts "Expired books job completed at #{Time.current}"
    puts "Total books expired: #{result || 0}"
  end

  desc "Show overdue books and reservations (dry run)"
  task show_overdue: :environment do
    puts "=== OVERDUE BOOKS (BORROWED & RESERVED) ==="
    overdue_books = Book.where(status: [:borrowed, :reserved])
                       .where('borrowed_until < ?', Time.current)

    if overdue_books.any?
      overdue_books.each do |book|
        status_text = book.status == 'borrowed' ? 'Due' : 'Reservation expires'
        puts "- #{book.title} (ID: #{book.id}) - Status: #{book.status.capitalize} - #{status_text}: #{book.borrowed_until}"
      end
      puts "\nTotal overdue books: #{overdue_books.count}"

      # Show breakdown by status
      borrowed_count = overdue_books.where(status: :borrowed).count
      reserved_count = overdue_books.where(status: :reserved).count
      puts "  - Overdue borrowed books: #{borrowed_count}"
      puts "  - Overdue reservations: #{reserved_count}"
    else
      puts "No overdue books or reservations found."
    end
  end

  desc "Create test data for expired books (development only)"
  task create_expired_test_data: :environment do
    unless Rails.env.development?
      puts "This task can only be run in development environment"
      exit 1
    end

    # Create an overdue borrowed book
    book1 = Book.first
    if book1
      book1.update!(
        status: :borrowed,
        borrowed_until: 2.days.ago
      )
      puts "Created overdue borrowed book: #{book1.title}"
    end

    # Create an overdue reservation
    book2 = Book.second
    if book2
      book2.update!(
        status: :reserved,
        borrowed_until: 1.day.ago
      )
      puts "Created overdue reservation: #{book2.title}"
    end

    puts "Test data created. Run 'rails books:show_overdue' to see the overdue items."
  end
end
