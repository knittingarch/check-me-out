require 'rails_helper'

RSpec.describe Author, type: :model do
  describe "associations" do
    it "has and belongs to many books" do
      author = create(:author_without_books)

      book1 = build(:book_without_authors)
      book1.authors = [author]
      book1.save!

      book2 = build(:book_without_authors)
      book2.authors = [author]
      book2.save!

      expect(author.books).to contain_exactly(book1, book2)
    end
  end

  describe "validations" do
    it "requires a name" do
      author = build(:author_without_books, name: nil)

      expect(author).not_to be_valid
      expect(author.errors[:name]).to include("can't be blank")
    end
  end
end
