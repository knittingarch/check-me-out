FactoryBot.define do
  factory :author do
    name { Faker::Book.author }
  end
  
  # Factory for creating authors without automatic book associations
  factory :author_without_books, class: 'Author' do
    name { Faker::Book.author }
  end
end
