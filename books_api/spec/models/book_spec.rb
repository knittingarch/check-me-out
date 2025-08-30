require "rails_helper"

RSpec.describe Book, type: :model do
  describe "enums" do
    it { should define_enum_for(:status).with_values(available: 0, checked_out: 1, reserved: 2) }
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

    describe "isbn validation" do
      it { should validate_presence_of(:isbn) }

      it "is invalid without an isbn" do
        book = build(:book, isbn: nil)
        expect(book).not_to be_valid
        expect(book.errors[:isbn]).to include("can't be blank")
      end

      it "is invalid with an empty isbn" do
        book = build(:book, isbn: "")
        expect(book).not_to be_valid
        expect(book.errors[:isbn]).to include("can't be blank")
      end

      describe "uniqueness validation" do
        it "validates uniqueness when it's a different book" do
          # Create a book first
          create(:book, title: "Unique Book", author: "Author", isbn: "123456789")

          # Try to create a DIFFERENT book with the same ISBN
          duplicate_book = build(:book, title: "Different Title", author: "Different Author", isbn: "123456789")
          expect(duplicate_book).not_to be_valid
          expect(duplicate_book.errors[:isbn]).to include("has already been taken")
        end

        it "allows duplicate ISBNs when there are multiple copies of the same book" do
          # Create first copy
          book1 = create(:book, title: "Same Book", author: "Same Author", isbn: "123456789")

          # Create second copy with same title, author, and ISBN (multiple copies)
          book2 = build(:book, title: "Same Book", author: "Same Author", isbn: "123456789")
          expect(book2).to be_valid
        end

        it "validates uniqueness for different books with same ISBN" do
          # Create first book
          create(:book, title: "Book One", author: "Author One", isbn: "123456789")

          # Try to create different book with same ISBN
          book2 = build(:book, title: "Book Two", author: "Author Two", isbn: "123456789")
          expect(book2).not_to be_valid
          expect(book2.errors[:isbn]).to include("has already been taken")
        end
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
        book = build(:book, status: "available")
        expect(book).to be_valid
      end

      it "is valid with checked_out status" do
        book = build(:book, status: "checked_out")
        expect(book).to be_valid
      end

      it "is valid with reserved status" do
        book = build(:book, status: "reserved")
        expect(book).to be_valid
      end
    end
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

  describe "instance methods" do
    let(:book) { create(:book) }

    describe "#reserve" do
      it "sets status to reserved and clears borrowed_until" do
        book.update(status: :available, borrowed_until: 1.week.from_now)

        result = book.reserve

        expect(result).to be true
        expect(book.status).to eq("reserved")
        expect(book.borrowed_until).to be_nil
      end

      it "can reserve a checked_out book" do
        book.update(status: :checked_out, borrowed_until: 1.week.from_now)

        book.reserve

        expect(book.status).to eq("reserved")
        expect(book.borrowed_until).to be_nil
      end
    end

    describe "#borrow" do
      it "sets status to checked_out and sets borrowed_until" do
        book.update(status: :available, borrowed_until: nil)

        result = book.borrow

        expect(result).to be true
        expect(book.status).to eq("checked_out")
        expect(book.borrowed_until).to be_present
        expect(book.borrowed_until).to be_within(1.minute).of(1.week.from_now)
      end

      it "can borrow a reserved book" do
        book.update(status: :reserved, borrowed_until: nil)

        book.borrow

        expect(book.status).to eq("checked_out")
        expect(book.borrowed_until).to be_present
      end
    end

    describe "#return" do
      it "sets status to available and clears borrowed_until" do
        book.update(status: :checked_out, borrowed_until: 1.week.from_now)

        result = book.return

        expect(result).to be true
        expect(book.status).to eq("available")
        expect(book.borrowed_until).to be_nil
      end

      it "can return a reserved book" do
        book.update(status: :reserved, borrowed_until: nil)

        book.return

        expect(book.status).to eq("available")
        expect(book.borrowed_until).to be_nil
      end
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

  describe "private methods" do
    describe "#multiple_copies_allowed?" do
      it "returns false when there is no existing book with same title, author, and isbn" do
        book = build(:book, title: "Unique Book", author: "Author", isbn: "123456789")
        expect(book.send(:multiple_copies_allowed?)).to be false
      end

      it "returns true when there is an existing book with same title, author, and isbn" do
        create(:book, title: "Same Book", author: "Same Author", isbn: "123456789")
        book2 = build(:book, title: "Same Book", author: "Same Author", isbn: "123456789")

        expect(book2.send(:multiple_copies_allowed?)).to be true
      end

      it "returns false for books with same ISBN but different title or author" do
        create(:book, title: "Book One", author: "Author One", isbn: "123456789")
        book2 = build(:book, title: "Book Two", author: "Author Two", isbn: "123456789")

        expect(book2.send(:multiple_copies_allowed?)).to be false
      end

      it "excludes the current record when checking for existing books" do
        book = create(:book, title: "Test Book", author: "Test Author", isbn: "123456789")
        expect(book.send(:multiple_copies_allowed?)).to be false
      end
    end
  end
end
