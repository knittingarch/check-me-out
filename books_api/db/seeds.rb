# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
puts "Clearing existing data..."
Book.destroy_all
Author.destroy_all

# Create fictional authors for testing
puts "Creating authors..."
# Create some fictional authors using Faker
authors = []

15.times do
  authors << FactoryBot.create(:author_without_books, name: Faker::Book.author)
end

puts "Creating books with specific titles for filter testing..."

# Books with matching words for filter testing
# Create test books with some matching titles for filter testing
puts "Creating test books..."
test_books = [
  { title: "The Great #{Faker::Book.title}", isbn: Faker::Code.isbn },
  { title: "Great #{Faker::Fantasy::Tolkien.location}", isbn: Faker::Code.isbn },
  { title: "#{Faker::Book.title} Adventure", isbn: Faker::Code.isbn },
  { title: "Adventure in #{Faker::Fantasy::Tolkien.location}", isbn: Faker::Code.isbn },
  { title: "#{Faker::Book.title} Story", isbn: Faker::Code.isbn },
  { title: "Story of #{Faker::Fantasy::Tolkien.character}", isbn: Faker::Code.isbn },
  { title: "Magic #{Faker::Book.title}", isbn: Faker::Code.isbn },
  { title: "The Magic #{Faker::Fantasy::Tolkien.race}", isbn: Faker::Code.isbn },
  { title: "#{Faker::Book.title} Tales", isbn: Faker::Code.isbn },
  { title: "Tales from #{Faker::Fantasy::Tolkien.location}", isbn: Faker::Code.isbn }
]

# Create the test books with specific statuses
test_books.each_with_index do |book_data, index|
  status = case index % 3
           when 0 then :available
           when 1 then :borrowed
           when 2 then :reserved
           end

  # Build book (don't save yet)
  book = Book.new(
    title: book_data[:title],
    isbn: book_data[:isbn],
    published_date: Faker::Date.between(from: 50.years.ago, to: Date.current),
    status: status,
    borrowed_until: if status == :available
                      nil
                    else
                      (status == :borrowed ? 1.week.from_now : 1.day.from_now)
                    end
  )

  # Assign authors
  if book_data[:author_name]
    author = authors.find { |a| a.name == book_data[:author_name] }
    book.authors = author ? [author] : [authors.sample]
  else
    book.authors = [authors.sample]
  end

  # Now save with authors assigned
  book.save!
end

puts "Creating multiple copies of popular books..."

# Create multiple copies of some popular books (same title, ISBN, and authors)
popular_books = [
  { title: "The #{Faker::Fantasy::Tolkien.character} Chronicles", isbn: Faker::Code.isbn, author_name: Faker::Book.author }, # rubocop:disable Layout/LineLength
  { title: "#{Faker::Book.title} and Beyond", isbn: Faker::Code.isbn, author_name: Faker::Book.author },
  { title: "Secrets of #{Faker::Fantasy::Tolkien.location}", isbn: Faker::Code.isbn, author_name: Faker::Book.author }
]

popular_books.each do |book_data|
  # Create 2-4 additional copies of each popular book
  copies_count = rand(2..4)
  copies_count.times do |_i|
    status = %i[available borrowed reserved].sample

    # Build book (don't save yet)
    book = Book.new(
      title: book_data[:title],
      isbn: book_data[:isbn],
      published_date: Faker::Date.between(from: 50.years.ago, to: Date.current),
      status: status,
      borrowed_until: if status == :available
                        nil
                      else
                        (status == :borrowed ? 1.week.from_now : 1.day.from_now)
                      end
    )

    # Assign authors
    author = authors.find { |a| a.name == book_data[:author_name] }
    book.authors = author ? [author] : [authors.sample]

    # Now save with authors assigned
    book.save!
  end
end

puts "Creating additional random books..."

# Create some additional random books
10.times do
  book_authors = if rand < 0.4 # 40% chance of having multiple authors
                   authors.sample(rand(2..3))
                 else
                   [authors.sample]
                 end

  status = %i[available borrowed reserved].sample

  # Build book (don't save yet)
  book = Book.new(
    title: Faker::Book.title,
    isbn: Faker::Code.isbn,
    published_date: Faker::Date.between(from: 50.years.ago, to: Date.current),
    status: status,
    borrowed_until: if status == :available
                      nil
                    else
                      (status == :borrowed ? 1.week.from_now : 1.day.from_now)
                    end
  )

  # Assign authors
  book.authors = book_authors

  # Now save with authors assigned
  book.save!
end

puts "Seed data created successfully!"
puts "Books created: #{Book.count}"
puts "Authors created: #{Author.count}"
puts "Available books: #{Book.available.count}"
puts "Borrowed books: #{Book.borrowed.count}"
puts "Reserved books: #{Book.reserved.count}"

# Show copy information
puts "\nBooks with multiple copies:"
Book.select(:title, :isbn, :copy_number).group_by { |b| [b.title, b.isbn] }.each do |key, books|
  next unless books.length > 1

  title, isbn = key
  puts "  #{title} (ISBN: #{isbn}) - #{books.length} copies " \
       "(copy numbers: #{books.map(&:copy_number).sort.join(', ')})"
end

puts "\nBooks for filter testing (containing common words):"
filter_words = ["Great", "Harry Potter", "Adventure", "The"]
filter_words.each do |word|
  matching_books = Book.joins(:authors).where("title ILIKE ?", "%#{word}%").distinct
  puts "  Books containing '#{word}': #{matching_books.count}"
  matching_books.limit(3).each do |book|
    puts "    - #{book.title} by #{book.authors.pluck(:name).join(', ')}"
  end
end
