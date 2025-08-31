require "rails_helper"

RSpec.describe "/books", type: :request do
  let(:valid_attributes) do
    {
      title: "Test Book",
      author: "Test Author",
      isbn: "123456789123X",
      published_date: "2023-01-01",
      status: "available"
    }
  end

  let(:invalid_attributes) do
    {
      title: "",
      author: "",
      isbn: nil
    }
  end

  let(:valid_headers) do
    { "Content-Type" => "application/json" }
  end

  describe "GET /index" do
    it "renders a successful response" do
      create(:book)

      get books_url, headers: valid_headers, as: :json

      expect(response).to be_successful
    end

    it "returns an empty array when no books exist" do
      get books_url, headers: valid_headers, as: :json

      expect(response).to be_successful
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns all books as JSON" do
      book1 = create(:book, title: "Book 1")
      book2 = create(:book, title: "Book 2")

      get books_url, headers: valid_headers, as: :json

      expect(response).to be_successful

      json_response = JSON.parse(response.body)
      titles = json_response.map { |book| book["title"] }

      expect(json_response.length).to eq(2)
      expect(titles).to include("Book 1", "Book 2")
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      book = create(:book)

      get book_url(book), headers: valid_headers, as: :json

      expect(response).to be_successful
    end

    it "returns the correct book data" do
      book = create(:book, title: "Specific Book", author: "Specific Author")

      get book_url(book), headers: valid_headers, as: :json

      expect(response).to be_successful

      json_response = JSON.parse(response.body)

      expect(json_response["title"]).to eq("Specific Book")
      expect(json_response["author"]).to eq("Specific Author")
      expect(json_response["id"]).to eq(book.id)
    end

    it "returns 404 for non-existent book" do
      get book_url(id: 999999), headers: valid_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new Book" do
        expect {
          post books_url,
               params: { book: valid_attributes }, headers: valid_headers, as: :json
        }.to change(Book, :count).by(1)
      end

      it "renders a JSON response with the new book" do
        post books_url,
             params: { book: valid_attributes }, headers: valid_headers, as: :json

        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including("application/json"))
      end

      it "returns the created book with correct attributes" do
        post books_url,
             params: { book: valid_attributes }, headers: valid_headers, as: :json

        json_response = JSON.parse(response.body)

        expect(json_response["title"]).to eq("Test Book")
        expect(json_response["author"]).to eq("Test Author")
        expect(json_response["isbn"]).to eq("123456789123X")  # String, not integer
        expect(json_response["status"]).to eq("available")
      end

      it "sets the location header" do
        post books_url,
             params: { book: valid_attributes }, headers: valid_headers, as: :json

        created_book = Book.last

        expect(response.headers["Location"]).to eq(book_url(created_book))
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) do
        {
          title: "Updated Book Title",
          author: "Updated Author"
        }
      end

      it "updates the requested book" do
        book = create(:book)

        patch book_url(book),
              params: { book: new_attributes }, headers: valid_headers, as: :json
        book.reload

        expect(book.title).to eq("Updated Book Title")
        expect(book.author).to eq("Updated Author")
      end

      it "renders a JSON response with the book" do
        book = create(:book)

        patch book_url(book),
              params: { book: new_attributes }, headers: valid_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(a_string_including("application/json"))
      end

      it "returns the updated book data" do
        book = create(:book, title: "Original Title")

        patch book_url(book),
              params: { book: new_attributes }, headers: valid_headers, as: :json

        json_response = JSON.parse(response.body)

        expect(json_response["title"]).to eq("Updated Book Title")
        expect(json_response["author"]).to eq("Updated Author")
      end

      it "updates book status" do
        book = create(:book, status: "available")

        patch book_url(book),
              params: { book: { status: "borrowed", borrowed_until: 1.week.from_now } },
              headers: valid_headers, as: :json

        book.reload

        expect(book.status).to eq("borrowed")
        expect(book.borrowed_until).to be_present
      end
    end

    context "with invalid parameters" do
      it "renders a JSON response with the book" do
        book = create(:book)

        patch book_url(book),
              params: { book: { title: "Updated Title" } }, headers: valid_headers, as: :json

        expect(response).to have_http_status(:ok)
      end

      it "returns 404 for non-existent book" do
        patch book_url(id: 999999),
              params: { book: { title: "Updated Title" } }, headers: valid_headers, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested book" do
      book = create(:book)

      expect {
        delete book_url(book), headers: valid_headers, as: :json
      }.to change(Book, :count).by(-1)
    end

    it "returns no content status" do
      book = create(:book)

      delete book_url(book), headers: valid_headers, as: :json

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for non-existent book" do
      delete book_url(id: 999999), headers: valid_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "actually removes the book from the database" do
      book = create(:book)
      book_id = book.id

      delete book_url(book), headers: valid_headers, as: :json

      expect { Book.find(book_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "Error handling" do
    it "handles invalid JSON in request body gracefully" do
      post books_url,
           params: "invalid json",
           headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "Parameter filtering" do
    it "only allows permitted parameters and ignores unpermitted ones" do
      book = create(:book)
      original_id = book.id

      patch book_url(book),
            params: {
              book: {
                title: "New Title",
                unpermitted_param: "should be ignored",
              }
            },
            headers: valid_headers, as: :json

      expect(response).to have_http_status(:ok)

      book.reload

      expect(book.title).to eq("New Title")
      expect(book.id).to eq(original_id)

      json_response = JSON.parse(response.body)

      expect(json_response).not_to have_key("unpermitted_param")
    end

    it "handles requests with only unpermitted parameters gracefully" do
      book = create(:book)
      original_title = book.title

      patch book_url(book),
            params: {
              book: {
                unpermitted_param: "should be ignored",
                another_bad_param: "also ignored"
              }
            },
            headers: valid_headers, as: :json

      expect(response).to have_http_status(:ok)

      book.reload
      expect(book.title).to eq(original_title)
    end

    it "prevents ID manipulation attempts" do
      book = create(:book)
      original_id = book.id

      patch book_url(book),
            params: {
              book: {
                id: 999999,
                title: "Hacked Title"
              }
            },
            headers: valid_headers, as: :json

      book.reload

      expect(book.id).to eq(original_id)
      expect(book.title).to eq("Hacked Title")
    end
  end
end
