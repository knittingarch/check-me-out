FactoryBot.define do
  factory :book do
    title { Faker::Book.title }
    author { Faker::Book.author }
    isbn { Faker::Code.isbn }
    published_date { Faker::Date.between(from: 50.years.ago, to: Date.current) }
    status { :available }
    borrowed_until { nil }

    trait :borrowed do
      status { :borrowed }
      borrowed_until { 1.week.from_now }
    end

    trait :reserved do
      status { :reserved }
      borrowed_until { nil }
    end
  end
end
