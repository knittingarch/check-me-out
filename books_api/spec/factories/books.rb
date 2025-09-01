FactoryBot.define do
  factory :book do
    title { Faker::Book.title }
    isbn { Faker::Code.isbn }
    published_date { Faker::Date.between(from: 50.years.ago, to: Date.current) }
    status { :available }
    borrowed_until { nil }

    after(:build) do |book|
      book.authors << build(:author_without_books)
    end

    trait :borrowed do
      status { :borrowed }
      borrowed_until { 1.week.from_now }
    end

    trait :reserved do
      status { :reserved }
      borrowed_until { nil }
    end
  end

  # Factory for creating books without automatic author associations
  factory :book_without_authors, class: 'Book' do
    title { Faker::Book.title }
    isbn { Faker::Code.isbn }
    published_date { Faker::Date.between(from: 50.years.ago, to: Date.current) }
    status { :available }
    borrowed_until { nil }
  end
end
