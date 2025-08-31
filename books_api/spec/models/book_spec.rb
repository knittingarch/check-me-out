require "rails_helper"

RSpec.describe Book, type: :model do
  describe "enums" do
    it { should define_enum_for(:status).with_values(available: 0, borrowed: 1, reserved: 2) }
  end

  describe "status behavior" do
    it "can be set to available and responds correctly" do
      book = create(:book)

      expect(book.available?).to be true
    end

    it "can be set to borrowed and responds correctly" do
      book = create(:book, :borrowed)

      expect(book.borrowed?).to be true
    end

    it "can be set to reserved and responds correctly" do
      book = create(:book, :reserved)

      expect(book.reserved?).to be true
    end
  end

  describe "validations" do
    describe "title validation" do
      it { should validate_presence_of(:title) }

      it "is invalid without a title" do
        book = build(:book, title: nil)

        expect(book).not_to be_valid
        expect(book.errors[:title]).to include("can't be blank")
      end

      it "is invalid with an empty title" do
        book = build(:book, title: "")

        expect(book).not_to be_valid
        expect(book.errors[:title]).to include("can't be blank")
      end

      it "is valid with a title" do
        book = build(:book, title: "Valid Title")

        expect(book).to be_valid
      end
    end

    describe "author validation" do
      it { should validate_presence_of(:author) }

      it "is invalid without an author" do
        book = build(:book, author: nil)

        expect(book).not_to be_valid
        expect(book.errors[:author]).to include("can't be blank")
      end

      it "is invalid with an empty author" do
        book = build(:book, author: "")

        expect(book).not_to be_valid
        expect(book.errors[:author]).to include("can't be blank")
      end

      it "is valid with an author" do
        book = build(:book, author: "Valid Author")

        expect(book).to be_valid
      end
    end

    describe "ISBN validation" do
      it { should validate_presence_of(:isbn) }

      it "is invalid without an ISBN" do
        book = build(:book, isbn: nil)

        expect(book).not_to be_valid
        expect(book.errors[:isbn]).to include("can't be blank")
      end

      it "is invalid with an empty ISBN" do
        book = build(:book, isbn: "")

        expect(book).not_to be_valid
        expect(book.errors[:isbn]).to include("can't be blank")
      end
    end

    describe "published_date validation" do
      it { should validate_presence_of(:published_date) }

      it "is invalid without a published_date" do
        book = build(:book, published_date: nil)

        expect(book).not_to be_valid
        expect(book.errors[:published_date]).to include("can't be blank")
      end

      it "is valid with a published_date" do
        book = build(:book, published_date: Date.current)

        expect(book).to be_valid
      end
    end

    describe "status validation" do
      it { should validate_presence_of(:status) }

      it "is invalid without a status" do
        book = build(:book, status: nil)

        expect(book).not_to be_valid
        expect(book.errors[:status]).to include("can't be blank")
      end

      it "is valid with available status" do
        book = build(:book, status: :available)

        expect(book).to be_valid
      end

      it "is valid with borrowed status" do
        book = build(:book, status: :borrowed)

        expect(book).to be_valid
      end

      it "is valid with reserved status" do
        book = build(:book, status: :reserved)

        expect(book).to be_valid
      end
    end
  end

  describe "instance methods" do
    let(:book) { create(:book, status: :available) }

    describe "#reserve" do
      it "sets status to reserved and clears borrowed_until" do
        result = book.reserve

        expect(result).to be true
        expect(book.status).to eq("reserved")
        expect(book.borrowed_until).to be_nil
      end

      it "cannot reserve a borrowed book" do
        book.update(status: :borrowed, borrowed_until: 1.week.from_now)

        result = book.reserve

        expect(result).to be false
        expect(book.status).to eq("borrowed")
      end
    end

    describe "#borrow" do
      it "sets status to borrowed and sets borrowed_until" do
        result = book.borrow

        expect(result).to be true
        expect(book.status).to eq("borrowed")
        expect(book.borrowed_until).to be_present
      end

      it "can borrow a reserved book" do
        book.update(status: :reserved, borrowed_until: nil)

        book.borrow

        expect(book.status).to eq("borrowed")
        expect(book.borrowed_until).to be_present
      end
    end

    describe "#return" do
      it "sets status to available and clears borrowed_until" do
        book.update(status: :borrowed, borrowed_until: 1.week.from_now)

        result = book.return

        expect(result).to be true
        expect(book.status).to eq("available")
        expect(book.borrowed_until).to be_nil
      end

      it "cannot update status on a reserved book to available" do
        book.update(status: :reserved, borrowed_until: nil)

        result = book.return

        expect(result).to be false
        expect(book.status).to eq("reserved")
      end
    end

    describe "#cancel_reservation" do
      it "sets status to available and clears borrowed_until" do
        book.update(status: :reserved, borrowed_until: nil)

        result = book.cancel_reservation

        expect(result).to be true
        expect(book.status).to eq("available")
        expect(book.borrowed_until).to be_nil
      end
    end
  end

  describe "ISBN uniqueness behavior" do
    describe "when creating different books" do
      it "validates ISBN uniqueness for different books" do
        create(:book, title: "First Book", author: "First Author", isbn: "123456789")
        duplicate_book = build(:book, title: "Second Book", author: "Second Author", isbn: "123456789")

        expect(duplicate_book).not_to be_valid
        expect(duplicate_book.errors[:isbn]).to include("has already been taken")
      end

      it "allows same ISBN for same book (multiple copies)" do
        create(:book, title: "Same Book", author: "Same Author", isbn: "123456789")
        second_copy = build(:book, title: "Same Book", author: "Same Author", isbn: "123456789")

        expect(second_copy).to be_valid
      end

      it "validates uniqueness when title differs but author and ISBN are same" do
        create(:book, title: "Original Title", author: "Same Author", isbn: "123456789")
        different_book = build(:book, title: "Different Title", author: "Same Author", isbn: "123456789")

        expect(different_book).not_to be_valid
        expect(different_book.errors[:isbn]).to include("has already been taken")
      end

      it "validates uniqueness when author differs but title and ISBN are same" do
        create(:book, title: "Same Title", author: "Original Author", isbn: "123456789")
        different_book = build(:book, title: "Same Title", author: "Different Author", isbn: "123456789")

        expect(different_book).not_to be_valid
        expect(different_book.errors[:isbn]).to include("has already been taken")
      end
    end

    describe "when updating existing books" do
      it "allows book to keep its own ISBN when updating other fields" do
        book = create(:book, title: "Original Title", author: "Original Author", isbn: "123456789")

        book.title = "Updated Title"
        expect(book).to be_valid
      end

      it "prevents changing to an ISBN that belongs to a different book" do
        create(:book, title: "Book One", author: "Author One", isbn: "111111111")
        book2 = create(:book, title: "Book Two", author: "Author Two", isbn: "222222222")

        book2.isbn = "111111111"
        expect(book2).not_to be_valid
        expect(book2.errors[:isbn]).to include("has already been taken")
      end
    end
  end
end
