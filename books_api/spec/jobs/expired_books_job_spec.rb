require 'rails_helper'

RSpec.describe ExpiredBooksJob, type: :job do
  describe '#perform' do
    context 'when there are overdue borrowed books' do
      before do
        @author = create(:author)
        @overdue_book = create(:book, authors: [@author], status: :borrowed, borrowed_until: 2.days.ago)
        @current_book = create(:book, authors: [@author], status: :borrowed, borrowed_until: 1.day.from_now)
      end

      it 'expires overdue borrowed books' do
        expect { described_class.perform_now }
          .to change { @overdue_book.reload.status }.from('borrowed').to('available')
          .and change { @overdue_book.reload.borrowed_until }.to(nil)
      end

      it 'does not affect books that are not overdue' do
        described_class.perform_now

        expect(@current_book.reload.status).to eq('borrowed')
        expect(@current_book.reload.borrowed_until).to be_present
      end
    end

    context 'when there are overdue reservations' do
      before do
        @author = create(:author)
        @overdue_reservation = create(:book, authors: [@author], status: :reserved, borrowed_until: 2.hours.ago)
        @current_reservation = create(:book, authors: [@author], status: :reserved, borrowed_until: 2.hours.from_now)
      end

      it 'expires overdue reservations' do
        expect { described_class.perform_now }
          .to change { @overdue_reservation.reload.status }.from('reserved').to('available')
          .and change { @overdue_reservation.reload.borrowed_until }.to(nil)
      end

      it 'does not affect reservations that are not overdue' do
        described_class.perform_now

        expect(@current_reservation.reload.status).to eq('reserved')
        expect(@current_reservation.reload.borrowed_until).to be_present
      end

      it 'does not affect reservations without borrowed_until date' do
        reservation_without_date = create(:book, authors: [@author], status: :reserved, borrowed_until: nil)

        described_class.perform_now

        expect(reservation_without_date.reload.status).to eq('reserved')
        expect(reservation_without_date.reload.borrowed_until).to be_nil
      end
    end

    context 'when there are no overdue books or reservations' do
      it 'does not change any book statuses' do
        author = create(:author)
        create(:book, authors: [author], status: :available)
        create(:book, authors: [author], status: :borrowed, borrowed_until: 1.week.from_now)

        expect { described_class.perform_now }
          .not_to change { Book.pluck(:status, :borrowed_until) }
      end
    end

    context 'with mixed scenarios' do
      before do
        @author = create(:author)
        @overdue_borrowed = create(:book, authors: [@author], status: :borrowed, borrowed_until: 1.day.ago)
        @overdue_reserved = create(:book, authors: [@author], status: :reserved, borrowed_until: 30.minutes.ago)
        @current_borrowed = create(:book, authors: [@author], status: :borrowed, borrowed_until: 3.days.from_now)
        @available_book = create(:book, authors: [@author], status: :available)
      end

      it 'only expires the overdue items' do
        described_class.perform_now

        expect(@overdue_borrowed.reload.status).to eq('available')
        expect(@overdue_borrowed.reload.borrowed_until).to be_nil

        expect(@overdue_reserved.reload.status).to eq('available')
        expect(@overdue_reserved.reload.borrowed_until).to be_nil

        expect(@current_borrowed.reload.status).to eq('borrowed')
        expect(@current_borrowed.reload.borrowed_until).to be_present

        expect(@available_book.reload.status).to eq('available')
        expect(@available_book.reload.borrowed_until).to be_nil
      end
    end

    context 'logging behavior' do
      it 'logs the start and completion of the job' do
        author = create(:author)
        overdue_book = create(:book, authors: [author], status: :borrowed, borrowed_until: 1.day.ago)

        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)

        described_class.perform_now

        expect(Rails.logger).to have_received(:info).with(/Starting ExpiredBooksJob/)
        expect(Rails.logger).to have_received(:info).with(/ExpiredBooksJob completed: 1 books expired/)
        expect(Rails.logger).to have_received(:info).with(/Expired book: #{overdue_book.title}/)
      end
    end

    context 'when book.return fails' do
      it 'logs a warning and continues' do
        author = create(:author)
        overdue_book = create(:book, authors: [author], status: :borrowed, borrowed_until: 1.day.ago)

        allow_any_instance_of(Book).to receive(:return).and_return(false)
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)

        described_class.perform_now

        expect(Rails.logger).to have_received(:warn).with(/Failed to expire book: #{overdue_book.title}/)
        expect(Rails.logger).to have_received(:info).with(/ExpiredBooksJob completed: 0 books expired/)
      end
    end
  end
end
