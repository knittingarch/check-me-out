class Book < ApplicationRecord
  has_and_belongs_to_many :authors

  enum status: { available: 0, borrowed: 1, reserved: 2 }

  validates :title, presence: true
  validates :authors, presence: true
  validates :isbn, presence: true, uniqueness: { unless: :multiple_copies_allowed? }
  validates :published_date, presence: true
  validates :status, presence: true

  # TODO: Determine how long the reservation can be held
  def reserve
    return false unless available?
    update(status: :reserved, borrowed_until: nil)
  end

  # TODO: When authentication is introduced, make sure to tie reservation to a specific user
  def borrow
    return false unless available? || reserved?
    update(status: :borrowed, borrowed_until: 1.week.from_now)
  end

  def return
    return false unless borrowed?
    update(status: :available, borrowed_until: nil)
  end

  def cancel_reservation
    return false unless reserved?
    update(status: :available, borrowed_until: nil)
  end

  private

  def multiple_copies_allowed?
    # Allow multiple copies if there's already a book with the same title,
    # authors, AND isbn (the same book)
    existing_books = Book.where(title: title, isbn: isbn).where.not(id: id)

    current_author_ids = if persisted?
      authors.pluck(:id).sort
    else
      # For unsaved records, get author IDs from the association
      authors.map(&:id).compact.sort
    end

    existing_books.any? do |existing_book|
      existing_book.authors.pluck(:id).sort == current_author_ids
    end
  end
end
