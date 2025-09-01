class ExpiredBooksJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting ExpiredBooksJob at #{Time.current}"

    expired_count = expire_overdue_books

    Rails.logger.info "ExpiredBooksJob completed: #{expired_count} books expired"
  end

  private

  def expire_overdue_books
    # Find all borrowed or reserved books where borrowed_until has passed
    overdue_books = Book.where(status: [:borrowed, :reserved])
                       .where('borrowed_until < ?', Time.current)
    expired_count = 0

    overdue_books.find_each do |book|
      if book.return
        Rails.logger.info "Expired book: #{book.title} (ID: #{book.id})"
        expired_count += 1
      else
        Rails.logger.warn "Failed to expire book: #{book.title} (ID: #{book.id})"
      end
    end

    expired_count
  end
end
