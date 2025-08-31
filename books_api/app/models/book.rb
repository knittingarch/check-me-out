class Book < ApplicationRecord
  enum status: { available: 0, borrowed: 1, reserved: 2 }

  validates :title, presence: true
  validates :author, presence: true
  validates :isbn, presence: true, uniqueness: { unless: :multiple_copies_allowed? }
  validates :published_date, presence: true
  validates :status, presence: true

  private

  def multiple_copies_allowed?
    # Allow multiple copies if there's already a book with the same title, author, AND isbn (the same book)
    Book.where(title: title, author: author, isbn: isbn).where.not(id: id).exists?
  end
end
