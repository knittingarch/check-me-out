require "rails_helper"

RSpec.describe ExpiredBooksJob, type: :job do
  describe "#perform" do
    context "when there are overdue borrowed books" do
      let(:author) { create(:author) }
      let(:overdue_book) { create(:book, authors: [author], status: :borrowed, borrowed_until: 2.days.ago) }
      let(:current_book) { create(:book, authors: [author], status: :borrowed, borrowed_until: 1.day.from_now) }

      it "expires overdue borrowed books" do
        # Ensure books are created
        overdue_book
        current_book

        expect { described_class.perform_now }
          .to change { overdue_book.reload.status }.from("borrowed").to("available")
          .and change { overdue_book.reload.borrowed_until }.to(nil)
      end

      it "does not affect books that are not overdue" do
        # Ensure books are created
        overdue_book
        current_book

        described_class.perform_now

        expect(current_book.reload.status).to eq("borrowed")
        expect(current_book.reload.borrowed_until).to be_present
      end
    end

    context "when there are overdue reserved books" do
      let(:author) { create(:author) }
      let(:overdue_reserved_book) { create(:book, authors: [author], status: :reserved, borrowed_until: 2.days.ago) }
      let(:current_reserved_book) { create(:book, authors: [author], status: :reserved, borrowed_until: 1.day.from_now) }

      it "expires overdue reserved books" do
        # Ensure books are created
        overdue_reserved_book
        current_reserved_book

        expect { described_class.perform_now }
          .to change { overdue_reserved_book.reload.status }.from("reserved").to("available")
          .and change { overdue_reserved_book.reload.borrowed_until }.to(nil)
      end

      it "does not affect reservations that are not overdue" do
        # Ensure books are created
        overdue_reserved_book
        current_reserved_book

        described_class.perform_now

        expect(current_reserved_book.reload.status).to eq("reserved")
        expect(current_reserved_book.reload.borrowed_until).to be_present
      end
    end

    context "when there are no overdue books or reservations" do
      it "does not change any book statuses" do
        author = create(:author)
        create(:book, authors: [author], status: :available)
        create(:book, authors: [author], status: :borrowed, borrowed_until: 1.week.from_now)

        expect { described_class.perform_now }
          .not_to(change { Book.pluck(:status, :borrowed_until) })
      end
    end

    context "when there are mixed status books" do
      let(:author) { create(:author) }
      let(:available_book) { create(:book, authors: [author], status: :available) }
      let(:overdue_borrowed) { create(:book, authors: [author], status: :borrowed, borrowed_until: 1.day.ago) }
      let(:overdue_reserved) { create(:book, authors: [author], status: :reserved, borrowed_until: 1.day.ago) }

      it "only affects overdue books with borrowed_until dates" do
        # Force creation of all books before running the job
        available_book
        overdue_borrowed
        overdue_reserved

        described_class.perform_now

        expect(available_book.reload.status).to eq("available")
        expect(overdue_borrowed.reload.status).to eq("available")
        expect(overdue_reserved.reload.status).to eq("available")
      end
    end

    context "with logging behavior" do
      let(:author) { create(:author) }
      let(:overdue_book) { create(:book, authors: [author], status: :borrowed, borrowed_until: 1.day.ago) }

      it "logs the job execution" do
        # Ensure book is created
        overdue_book

        allow(Rails.logger).to receive(:info)

        described_class.perform_now

        expect(Rails.logger).to have_received(:info).with(/Starting ExpiredBooksJob/)
        expect(Rails.logger).to have_received(:info).with(/ExpiredBooksJob completed: 1 books expired/)
      end
    end

    context "when book return fails" do
      it "logs a warning and continues" do
        author = create(:author)
        overdue_book = create(:book, authors: [author], status: :borrowed, borrowed_until: 1.day.ago)

        allow_any_instance_of(Book).to receive(:return).and_return(false) # rubocop:disable RSpec/AnyInstance
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)

        described_class.perform_now

        expect(Rails.logger).to have_received(:warn).with(/Failed to expire book: #{overdue_book.title}/)
        expect(Rails.logger).to have_received(:info).with(/ExpiredBooksJob completed: 0 books expired/)
      end
    end
  end
end
