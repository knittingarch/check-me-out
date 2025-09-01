FactoryBot.define do
  factory :author do
    name { Faker::Book.author }
    
    # Create associated books after the author is created
    after(:create) do |author|
      author.books << create(:book_without_authors) unless author.books.any?
    end
  end
  
  # Factory for creating authors without automatic book associations
  factory :author_without_books, class: 'Author' do
    name { Faker::Book.author }
  end
end
