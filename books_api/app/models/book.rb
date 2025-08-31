class Book < ApplicationRecord
  enum status: { available: 0, borrowed: 1, reserved: 2 }

  validates :title, presence: true
  validates :author, presence: true
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
    # Allow multiple copies if there's already a book with the same title, author, AND isbn (the same book)
    Book.where(title: title, author: author, isbn: isbn).where.not(id: id).exists?
  end
end
