class Book < ApplicationRecord
  enum status: { available: 0, checked_out: 1, reserved: 2 }

  validates :title, presence: true
  validates :author, presence: true
  validates :isbn, presence: true, uniqueness: { unless: :multiple_copies_allowed? }
  validates :published_date, presence: true
  validates :status, presence: true

  private

  def multiple_copies_allowed?
    # Allow multiple copies if there's already a book with the same title, author, AND isbn
    # This means it's the same book, just multiple copies
    existing_book = Book.where(title: title, author: author, isbn: isbn).where.not(id: id).first
    existing_book.present?
  end
end
