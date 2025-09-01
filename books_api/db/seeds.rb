# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
puts "Clearing existing data..."
Book.destroy_all
Author.destroy_all

# Create authors using FactoryBot
puts "Creating authors..."
authors = []
10.times do
  authors << FactoryBot.create(:author)
end

# Create books with different statuses using FactoryBot
puts "Creating books with varied statuses..."

# Create 5 available books
5.times do
  # Decide which authors to associate
  book_authors = []
  if rand < 0.4  # 40% chance of having multiple authors
    book_authors = authors.sample(rand(2..3))
  else
    book_authors = [authors.sample]
  end
  FactoryBot.create(:book, authors: book_authors)
end

# Create 3 borrowed books using the :borrowed trait
3.times do
  book_authors = []
  if rand < 0.3  # 30% chance of having multiple authors
    book_authors = authors.sample(rand(2..3))
  else
    book_authors = [authors.sample]
  end
  FactoryBot.create(:book, :borrowed, authors: book_authors)
end

# Create 2 reserved books using the :reserved trait
2.times do
  book_authors = []
  if rand < 0.5  # 50% chance of having multiple authors
    book_authors = authors.sample(rand(2..3))
  else
    book_authors = [authors.sample]
  end
  FactoryBot.create(:book, :reserved, authors: book_authors)
end

puts "Seed data created successfully!"
puts "Books created: #{Book.count}"
puts "Authors created: #{Author.count}"
puts "Available books: #{Book.available.count}"
puts "Borrowed books: #{Book.borrowed.count}"
puts "Reserved books: #{Book.reserved.count}"
