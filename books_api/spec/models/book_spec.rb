require "rails_helper"

RSpec.describe Book, type: :model do
  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(available: 0, borrowed: 1, reserved: 2) }
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
      it { is_expected.to validate_presence_of(:title) }

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

    describe "authors validation" do
      it { is_expected.to validate_presence_of(:authors) }

      it "requires authors for validation" do
        book = build(:book_without_authors)

        expect(book).not_to be_valid
        expect(book.errors[:authors]).to include("can't be blank")
      end

      it "is valid with authors" do
        book = build(:book)

        expect(book).to be_valid
      end
    end

    describe "ISBN validation" do
      it { is_expected.to validate_presence_of(:isbn) }

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
      it { is_expected.to validate_presence_of(:published_date) }

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
      it { is_expected.to validate_presence_of(:status) }

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
      it "sets status to reserved and updates borrowed_until" do
        result = book.reserve

        expect(result).to be true
        expect(book.status).to eq("reserved")
        expect(book.borrowed_until).to be_present
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

      it "cannot borrow a reserved book" do
        book.update(status: :reserved, borrowed_until: 1.day.from_now)

        result = book.borrow

        expect(result).to be false
        expect(book.status).to eq("reserved")
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

      it "can update status on a reserved book to available" do
        book.update(status: :reserved)

        result = book.return

        expect(result).to be true
        expect(book.status).to eq("available")
        expect(book.borrowed_until).to be_nil
      end
    end

    describe "#cancel_reservation" do
      it "sets status to available and clears borrowed_until" do
        book.update(status: :reserved)

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
        author1 = create(:author_without_books, name: "Author One")
        author2 = create(:author_without_books, name: "Author Two")

        first_book = build(:book_without_authors, title: "First Book", isbn: "123456789")
        first_book.authors = [author1]
        first_book.save!

        duplicate_book = build(:book_without_authors, title: "Second Book", isbn: "123456789")
        duplicate_book.authors = [author2]

        expect(duplicate_book).not_to be_valid
        expect(duplicate_book.errors[:isbn]).to include("has already been taken")
      end

      it "allows same ISBN for same book (multiple copies)" do
        author = create(:author_without_books, name: "Same Author")

        first_book = build(:book_without_authors, title: "Same Book", isbn: "123456789")
        first_book.authors = [author]
        first_book.save!

        second_copy = build(:book_without_authors, title: "Same Book", isbn: "123456789")
        second_copy.authors = [author]

        expect(second_copy).to be_valid
        
        second_copy.save!
        expect(second_copy.copy_number).to eq(2)        # Test a third copy
        third_copy = build(:book_without_authors, title: "Same Book", isbn: "123456789")
        third_copy.authors = [author]
        third_copy.save!
        expect(third_copy.copy_number).to eq(3)
      end

      it "validates uniqueness when title differs but ISBN is same" do
        author1 = create(:author_without_books, name: "Author One")
        author2 = create(:author_without_books, name: "Author Two")

        first_book = build(:book_without_authors, title: "Original Title", isbn: "123456789")
        first_book.authors = [author1]
        first_book.save!

        different_book = build(:book_without_authors, title: "Different Title", isbn: "123456789")
        different_book.authors = [author2]

        expect(different_book).not_to be_valid
        expect(different_book.errors[:isbn]).to include("has already been taken")
      end

      it "validates uniqueness when authors differ but title and ISBN are same" do
        author1 = create(:author_without_books, name: "Author One")
        author2 = create(:author_without_books, name: "Author Two")

        first_book = build(:book_without_authors, title: "Same Title", isbn: "123456789")
        first_book.authors = [author1]
        first_book.save!

        different_book = build(:book_without_authors, title: "Same Title", isbn: "123456789")
        different_book.authors = [author2]

        expect(different_book).not_to be_valid
        expect(different_book.errors[:isbn]).to include("has already been taken")
      end
    end

    describe "when updating existing books" do
      it "allows book to keep its own ISBN when updating other fields" do
        author = create(:author_without_books, name: "Test Author")
        book = build(:book_without_authors, title: "Original Title", isbn: "123456789")
        book.authors = [author]
        book.save!

        book.title = "Updated Title"
        expect(book).to be_valid
      end

      it "prevents changing to an ISBN that belongs to a different book" do
        author1 = create(:author_without_books, name: "Author One")
        author2 = create(:author_without_books, name: "Author Two")

        book1 = build(:book_without_authors, title: "Book One", isbn: "111111111")
        book1.authors = [author1]
        book1.save!

        book2 = build(:book_without_authors, title: "Book Two", isbn: "222222222")
        book2.authors = [author2]
        book2.save!

        book2.isbn = "111111111"
        expect(book2).not_to be_valid
        expect(book2.errors[:isbn]).to include("has already been taken")
      end
    end
  end

  describe "copy number management" do
    it "automatically increments copy_number for duplicate books" do
      author = create(:author_without_books, name: "Test Author")

      # First copy
      book1 = build(:book_without_authors, title: "Test Book", isbn: "111111111")
      book1.authors = [author]
      book1.save!
      expect(book1.copy_number).to eq(1)

      # Second copy
      book2 = build(:book_without_authors, title: "Test Book", isbn: "111111111")
      book2.authors = [author]
      book2.save!
      expect(book2.copy_number).to eq(2)

      # Third copy
      book3 = build(:book_without_authors, title: "Test Book", isbn: "111111111")
      book3.authors = [author]
      book3.save!
      expect(book3.copy_number).to eq(3)
    end

    it "handles copy numbers correctly for books with multiple authors" do
      author1 = create(:author_without_books, name: "Author One")
      author2 = create(:author_without_books, name: "Author Two")

      # First copy with two authors
      book1 = build(:book_without_authors, title: "Multi-Author Book", isbn: "222222222")
      book1.authors = [author1, author2]
      book1.save!
      expect(book1.copy_number).to eq(1)

      # Second copy with same authors
      book2 = build(:book_without_authors, title: "Multi-Author Book", isbn: "222222222")
      book2.authors = [author1, author2]
      book2.save!
      expect(book2.copy_number).to eq(2)
    end
  end
end
