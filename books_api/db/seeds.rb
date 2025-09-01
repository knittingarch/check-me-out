# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
puts "Clearing existing data..."
Book.destroy_all
Author.destroy_all

# Create specific authors for testing
puts "Creating authors..."
# Create some specific authors for testing
famous_authors = [
  "J.K. Rowling",
  "Stephen King",
  "Agatha Christie",
  "George Orwell",
  "Jane Austen",
  "Ernest Hemingway",
  "F. Scott Fitzgerald",
  "Harper Lee",
  "Mark Twain",
  "Charles Dickens"
]

authors = famous_authors.map do |name|
  FactoryBot.create(:author_without_books, name: name)
end

# Create additional random authors
5.times do
  authors << FactoryBot.create(:author_without_books)
end

puts "Creating books with specific titles for filter testing..."

# Books with matching words for filter testing
test_books = [
  { title: "The Great Gatsby", isbn: "9780743273565", author_name: "F. Scott Fitzgerald" },
  { title: "The Great Adventure", isbn: "9780123456789", author_name: nil },
  { title: "Great Expectations", isbn: "9780141439563", author_name: "Charles Dickens" },
  { title: "Harry Potter and the Philosopher's Stone", isbn: "9780747532699", author_name: "J.K. Rowling" },
  { title: "Harry Potter and the Chamber of Secrets", isbn: "9780747538493", author_name: "J.K. Rowling" },
  { title: "The Shining", isbn: "9780307743657", author_name: "Stephen King" },
  { title: "It", isbn: "9781501142970", author_name: "Stephen King" },
  { title: "Murder on the Orient Express", isbn: "9780062693662", author_name: "Agatha Christie" },
  { title: "And Then There Were None", isbn: "9780062073488", author_name: "Agatha Christie" },
  { title: "Pride and Prejudice", isbn: "9780141439518", author_name: "Jane Austen" },
  { title: "1984", isbn: "9780451524935", author_name: "George Orwell" },
  { title: "Animal Farm", isbn: "9780451526342", author_name: "George Orwell" },
  { title: "To Kill a Mockingbird", isbn: "9780061120084", author_name: "Harper Lee" },
  { title: "The Adventures of Tom Sawyer", isbn: "9780486400778", author_name: "Mark Twain" },
  { title: "The Adventure Begins", isbn: "9780999888777", author_name: nil }
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
  { title: "The Great Gatsby", isbn: "9780743273565", author_name: "F. Scott Fitzgerald" },
  { title: "Harry Potter and the Philosopher's Stone", isbn: "9780747532699", author_name: "J.K. Rowling" },
  { title: "1984", isbn: "9780451524935", author_name: "George Orwell" }
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
