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

      get books_url, headers: valid_headers

      expect(response).to be_successful
    end

    it "returns an empty array when no books exist" do
      get books_url, headers: valid_headers

      expect(response).to be_successful
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns all books as JSON" do
      book1 = create(:book, title: "Book 1")
      book2 = create(:book, title: "Book 2")

      get books_url, headers: valid_headers

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

      get book_url(book), headers: valid_headers

      expect(response).to be_successful
    end

    it "returns the correct book data" do
      book = create(:book, title: "Specific Book", author: "Specific Author")

      get book_url(book), headers: valid_headers

      expect(response).to be_successful

      json_response = JSON.parse(response.body)

      expect(json_response["title"]).to eq("Specific Book")
      expect(json_response["author"]).to eq("Specific Author")
      expect(json_response["id"]).to eq(book.id)
    end

    it "returns 404 for non-existent book" do
      get book_url(id: 999999), headers: valid_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new Book" do
        expect {
          post books_url,
               params: { book: valid_attributes }.to_json, headers: valid_headers
        }.to change(Book, :count).by(1)
      end

      it "renders a JSON response with the new book" do
        post books_url,
             params: { book: valid_attributes }.to_json, headers: valid_headers

        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including("application/json"))
      end

      it "returns the created book with correct attributes" do
        post books_url,
             params: { book: valid_attributes }.to_json, headers: valid_headers

        json_response = JSON.parse(response.body)

        expect(json_response["title"]).to eq("Test Book")
        expect(json_response["author"]).to eq("Test Author")
        expect(json_response["isbn"]).to eq("123456789123X")  # String, not integer
        expect(json_response["status"]).to eq("available")
      end

      it "sets the location header" do
        post books_url,
             params: { book: valid_attributes }.to_json, headers: valid_headers

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
              params: { book: new_attributes }.to_json, headers: valid_headers
        book.reload

        expect(book.title).to eq("Updated Book Title")
        expect(book.author).to eq("Updated Author")
      end

      it "renders a JSON response with the book" do
        book = create(:book)

        patch book_url(book),
              params: { book: new_attributes }.to_json, headers: valid_headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(a_string_including("application/json"))
      end

      it "returns the updated book data" do
        book = create(:book, title: "Original Title")

        patch book_url(book),
              params: { book: new_attributes }.to_json, headers: valid_headers

        json_response = JSON.parse(response.body)

        expect(json_response["title"]).to eq("Updated Book Title")
        expect(json_response["author"]).to eq("Updated Author")
      end

      it "updates book status" do
        book = create(:book, status: "available")

        patch book_url(book),
              params: { book: { status: "borrowed", borrowed_until: 1.week.from_now } }.to_json,
              headers: valid_headers

        book.reload

        expect(book.status).to eq("borrowed")
        expect(book.borrowed_until).to be_present
      end
    end

    context "with invalid parameters" do
      it "renders a JSON response with the book" do
        book = create(:book)

        patch book_url(book),
              params: { book: { title: "Updated Title" } }.to_json, headers: valid_headers

        expect(response).to have_http_status(:ok)
      end

      it "returns 404 for non-existent book" do
        patch book_url(id: 999999),
              params: { book: { title: "Updated Title" } }.to_json, headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested book" do
      book = create(:book)

      expect {
        delete book_url(book), headers: valid_headers
      }.to change(Book, :count).by(-1)
    end

    it "returns no content status" do
      book = create(:book)

      delete book_url(book), headers: valid_headers

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for non-existent book" do
      delete book_url(id: 999999), headers: valid_headers

      expect(response).to have_http_status(:not_found)
    end

    it "actually removes the book from the database" do
      book = create(:book)
      book_id = book.id

      delete book_url(book), headers: valid_headers

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
            }.to_json,
            headers: valid_headers

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
            }.to_json,
            headers: valid_headers

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
            }.to_json,
            headers: valid_headers

      book.reload

      expect(book.id).to eq(original_id)
      expect(book.title).to eq("Hacked Title")
    end
  end

  describe "GET /books/search" do
    before do
      create(:book, title: "Ruby for Beginners", author: "Jane Smith", isbn: "9780123456789", status: "available")
      create(:book, title: "JavaScript Fundamentals", author: "Ruby Johnson", isbn: "9780987654321", status: "borrowed", borrowed_until: 1.week.from_now)
      create(:book, title: "Python Programming", author: "John Doe", isbn: "9781234567ruby", status: "reserved")
      create(:book, title: "Data Science Guide", author: "Alice Brown", isbn: "9780555666777", status: "available")
      create(:book, title: "Advanced Ruby", author: "Bob Wilson", isbn: "9781111222333", status: "borrowed", borrowed_until: 2.days.from_now)
    end

    context "with valid search parameter" do
      it "returns books matching title search" do
        get "/books/search?q=JavaScript", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)

        book = json_response.first
        expect(book["title"]).to eq("JavaScript Fundamentals")
        expect(book["author"]).to eq("Ruby Johnson")
        expect(book["isbn"]).to eq("9780987654321")
      end

      it "returns books matching author search" do
        get "/books/search?q=Smith", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)

        book = json_response.first
        expect(book["author"]).to eq("Jane Smith")
        expect(book["title"]).to eq("Ruby for Beginners")
        expect(book["isbn"]).to eq("9780123456789")
      end

      it "returns books matching ISBN search" do
        get "/books/search?q=9780123456789", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)

        book = json_response.first
        expect(book["isbn"]).to eq("9780123456789")
        expect(book["title"]).to eq("Ruby for Beginners")
        expect(book["author"]).to eq("Jane Smith")
      end

      it "returns books matching partial ISBN search" do
        get "/books/search?q=555666", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)

        book = json_response.first
        expect(book["isbn"]).to eq("9780555666777")
        expect(book["title"]).to eq("Data Science Guide")
        expect(book["author"]).to eq("Alice Brown")
      end

      it "performs case-insensitive search" do
        get "/books/search?q=DAta", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
      end

      it "returns partial matches" do
        get "/books/search?q=Guide", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)

        book = json_response.first
        expect(book["title"]).to eq("Data Science Guide")
        expect(book["author"]).to eq("Alice Brown")
        expect(book["isbn"]).to eq("9780555666777")
      end

      it "strips surrounding double quotes from search query" do
        get '/books/search?q="Python"', headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)

        book = json_response.first
        expect(book["title"]).to eq("Python Programming")
        expect(book["author"]).to eq("John Doe")
        expect(book["isbn"]).to eq("9781234567ruby")
      end

      it "strips surrounding single quotes from search query" do
        get "/books/search?q='JavaScript'", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)

        book = json_response.first
        expect(book["title"]).to eq("JavaScript Fundamentals")
        expect(book["author"]).to eq("Ruby Johnson")
        expect(book["isbn"]).to eq("9780987654321")
      end

      it "returns empty array when no matches found" do
        get "/books/search?q=Nonexistent Book", headers: valid_headers

        expect(response).to be_successful
        expect(JSON.parse(response.body)).to eq([])
      end

      it "searches across multiple fields simultaneously" do
        get "/books/search?q=ruby", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(4)

        # Extract the returned books' data for easier assertions
        returned_titles = json_response.map { |book| book["title"] }
        returned_authors = json_response.map { |book| book["author"] }
        returned_isbns = json_response.map { |book| book["isbn"] }

        expect(returned_titles).to include("Ruby for Beginners", "Advanced Ruby")  # "ruby" in title
        expect(returned_authors).to include("Ruby Johnson")                        # "ruby" in author
        expect(returned_isbns).to include("9781234567ruby")                       # "ruby" in ISBN

        expect(returned_titles).to match_array([
          "Ruby for Beginners",
          "Advanced Ruby",
          "JavaScript Fundamentals",
          "Python Programming"
        ])
      end
    end

    context "without search parameter" do
      it "returns bad request error when q parameter is missing" do
        get "/books/search", headers: valid_headers

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("At least one search parameter is required")
      end

      it "returns all books when q parameter is empty" do
        get "/books/search?q=", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(5) # Should return all books created in before block
      end

      it "returns all books when q parameter is only whitespace" do
        get "/books/search?q=   ", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(5) # Should return all books created in before block
      end
    end

    context "response format" do
      it "returns JSON content type" do
        get "/books/search?q=JavaScript", headers: valid_headers

        expect(response).to be_successful
        expect(response.content_type).to match(a_string_including("application/json"))
      end

      it "returns complete book objects with all attributes" do
        get "/books/search?q=Ruby", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)
        book = json_response.first

        expect(book).to have_key("id")
        expect(book).to have_key("title")
        expect(book).to have_key("author")
        expect(book).to have_key("isbn")
        expect(book).to have_key("published_date")
        expect(book).to have_key("status")
        expect(book).to have_key("created_at")
        expect(book).to have_key("updated_at")
      end
    end

    context "with multiple title search" do
      it "searches for multiple titles with comma separation" do
        get "/books/search?title=Ruby,JavaScript", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(3)
        titles = json_response.map { |book| book["title"] }
        expect(titles).to include("Ruby for Beginners", "Advanced Ruby", "JavaScript Fundamentals")
      end

      it "handles empty values in comma-separated titles" do
        get "/books/search?title=Ruby,,JavaScript,", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(3)
      end

      it "limits number of title filters" do
        many_titles = Array.new(15, "Ruby").join(',')
        get "/books/search?title=#{many_titles}", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Too many title filters")
      end
    end

    context "with multiple author search" do
      it "searches for multiple authors with comma separation" do
        get "/books/search?author=Jane Smith,Bob Wilson", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(2)
        authors = json_response.map { |book| book["author"] }
        titles = json_response.map { |book| book["title"] }
        expect(authors).to include("Jane Smith", "Bob Wilson")
        expect(titles).to include("Ruby for Beginners", "Advanced Ruby")
      end

      it "limits number of author filters" do
        many_authors = Array.new(15, "Smith").join(',')
        get "/books/search?author=#{many_authors}", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Too many author filters")
      end
    end

    context "with multiple ISBN search" do
      it "searches for multiple ISBNs with comma separation" do
        get "/books/search?isbn=9780123456789,9780987654321", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(2)
        isbns = json_response.map { |book| book["isbn"] }
        titles = json_response.map { |book| book["title"] }
        expect(isbns).to include("9780123456789", "9780987654321")
        expect(titles).to include("Ruby for Beginners", "JavaScript Fundamentals")
      end

      it "limits number of ISBN filters" do
        many_isbns = Array.new(15, "123456789").join(',')
        get "/books/search?isbn=#{many_isbns}", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Too many ISBN filters")
      end
    end

    context "with status filtering" do
      it "filters books by available status" do
        get "/books/search?status=available", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(2) # Ruby for Beginners and Data Science Guide
        titles = json_response.map { |book| book["title"] }
        expect(titles).to include("Ruby for Beginners", "Data Science Guide")
        json_response.each do |book|
          expect(book["status"]).to eq("available")
        end
      end

      it "filters books by borrowed status" do
        get "/books/search?status=borrowed", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(2) # JavaScript Fundamentals and Advanced Ruby
        titles = json_response.map { |book| book["title"] }
        expect(titles).to include("JavaScript Fundamentals", "Advanced Ruby")
        json_response.each do |book|
          expect(book["status"]).to eq("borrowed")
        end
      end

      it "returns error for invalid status" do
        get "/books/search?status=invalid", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Invalid status")
        expect(json_response["error"]).to include("available, borrowed, reserved")
      end
    end

    context "with borrowed until date filtering" do
      it "finds books that will be available by the given date" do
        future_date = 3.days.from_now.strftime("%Y-%m-%d")
        get "/books/search?borrowed_until=#{future_date}", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        # Should find:
        # - Books not currently borrowed (borrowed_until IS NULL): Ruby for Beginners, Data Science Guide, Python Programming
        # - Books that will be returned by 3 days from now: Advanced Ruby (returns in 2 days)
        # Should NOT find: JavaScript Fundamentals (returns in 1 week > 3 days)
        expect(json_response.length).to eq(4)

        titles = json_response.map { |book| book["title"] }
        expect(titles).to include("Ruby for Beginners", "Data Science Guide", "Python Programming", "Advanced Ruby")
        expect(titles).not_to include("JavaScript Fundamentals")
      end

      it "returns error for invalid date format" do
        get "/books/search?borrowed_until=invalid-date", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Invalid date format")
        expect(json_response["error"]).to include("YYYY-MM-DD")
      end
    end

    context "with combined search parameters" do
      it "combines title and status filters" do
        get "/books/search?title=Ruby&status=available", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)
        book = json_response.first
        expect(book["title"]).to eq("Ruby for Beginners")
        expect(book["status"]).to eq("available")
      end

      it "combines author and status filters" do
        get "/books/search?author=Johnson&status=borrowed", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)
        book = json_response.first
        expect(book["author"]).to eq("Ruby Johnson")
        expect(book["status"]).to eq("borrowed")
      end

      it "combines general search with status filter" do
        get "/books/search?q=Ruby&status=borrowed", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        # Should find JavaScript Fundamentals (author: Ruby Johnson, status: borrowed)
        # and Advanced Ruby (title contains Ruby, status: borrowed)
        expect(json_response.length).to eq(2)

        titles = json_response.map { |book| book["title"] }
        expect(titles).to include("JavaScript Fundamentals", "Advanced Ruby")

        json_response.each do |book|
          expect(book["status"]).to eq("borrowed")
        end
      end

      it "finds available books by ISBN that will be available by a given date" do
        # Use a date far in the future to ensure it includes books that will be returned by then
        future_date = 2.weeks.from_now.strftime("%Y-%m-%d")
        get "/books/search?isbn=9780987654321,9780555666777&borrowed_until=#{future_date}&status=available", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)
        book = json_response.first
        expect(book["title"]).to eq("Data Science Guide")
      end
    end

    context "enhanced error handling" do
      it "requires at least one search parameter" do
        get "/books/search", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("At least one search parameter is required")
      end

      it "handles whitespace-only parameters gracefully" do
        get "/books/search?title=   ", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("At least one search parameter is required")
      end
    end
  end
end
