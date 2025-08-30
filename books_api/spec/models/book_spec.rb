require "rails_helper"

RSpec.describe Book, type: :model do
  describe "enums" do
    it { should define_enum_for(:status).with_values(available: 0, checked_out: 1, reserved: 2) }
  end

  describe "factory" do
    it "has a valid factory" do
      book = build(:book)
      expect(book).to be_valid
    end
  end

  describe "traits" do
    it "creates a book with checked_out trait" do
      book = build(:book, :checked_out)
      expect(book.status).to eq("checked_out")
      expect(book.borrowed_until).to be_present
    end

    it "creates a book with reserved trait" do
      book = build(:book, :reserved)
      expect(book.status).to eq("reserved")
      expect(book.borrowed_until).to be_nil
    end
  end

  describe "status behavior" do
    it "can be set to available and responds correctly" do
      book = create(:book)
      expect(book.available?).to be true
    end

    it "can be set to checked_out and responds correctly" do
      book = create(:book, :checked_out)
      expect(book.checked_out?).to be true
    end
  end
end
