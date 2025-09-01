class Book < ApplicationRecord
  has_and_belongs_to_many :authors

  enum :status, { available: 0, borrowed: 1, reserved: 2 }

  validates :title, presence: true
  validates :authors, presence: true
  validates :isbn, presence: true, uniqueness: { unless: :multiple_copies_allowed? }
  validates :published_date, presence: true
  validates :status, presence: true

  def authors_sorted_by_name
    authors.order(:name)
  end

  def reserve
    return false unless available?

    update(status: :reserved, borrowed_until: 1.day.from_now)
  end

  # TODO: When authentication is introduced, make sure to tie reservation to a specific user
  def borrow
    return false unless available?

    update(status: :borrowed, borrowed_until: 1.week.from_now)
  end

  def return
    return false unless borrowed? || reserved?

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

    current_author_ids = if persisted?
                           authors.pluck(:id).sort
                         else
                           # For unsaved records, get author IDs from the association
                           authors.map(&:id).compact.sort
                         end

    # Find books with same title/isbn that have the exact same set of authors
    # Use a more efficient database query instead of loading and iterating
    Book.joins(:authors)
        .where(title: title, isbn: isbn)
        .where.not(id: id)
        .group("books.id")
        .having("array_agg(authors.id ORDER BY authors.id) = ?", "{#{current_author_ids.join(',')}}")
        .exists?
  end
end
