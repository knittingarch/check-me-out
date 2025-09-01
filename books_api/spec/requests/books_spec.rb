require "rails_helper"

RSpec.describe "/books", type: :request do
  let(:test_author) { create(:author_without_books, name: "Test Author") }

  let(:valid_attributes) do
    {
      title: "Test Book",
      author_ids: [test_author.id],
      isbn: "123456789123X",
      published_date: "2023-01-01",
      status: "available"
    }
  end

  let(:invalid_attributes) do
    {
      title: "",
      author_ids: [],
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
      titles = json_response.pluck("title")

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
      book = create(:book, title: "Specific Book")
      book.authors.first.update(name: "Specific Author")

      get book_url(book), headers: valid_headers

      expect(response).to be_successful

      json_response = JSON.parse(response.body)

      expect(json_response["title"]).to eq("Specific Book")
      expect(json_response["authors"]).to be_an(Array)
      expect(json_response["authors"].first["name"]).to eq("Specific Author")
      expect(json_response["id"]).to eq(book.id)
    end

    it "returns 404 for non-existent book" do
      get book_url(id: 999_999), headers: valid_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new Book" do
        expect do
          post books_url,
               params: { book: valid_attributes }.to_json, headers: valid_headers
        end.to change(Book, :count).by(1)
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
        created_book = Book.find(json_response["id"])

        expect(json_response["title"]).to eq("Test Book")
        expect(json_response["isbn"]).to eq("123456789123X")
        expect(json_response["status"]).to eq("available")
        expect(created_book.authors).to include(test_author)
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
      let(:updated_author) { create(:author_without_books, name: "Updated Author") }
      let(:new_attributes) do
        {
          title: "Updated Book Title",
          author_ids: [updated_author.id]
        }
      end

      it "updates the requested book" do
        book = create(:book)

        patch book_url(book),
              params: { book: new_attributes }.to_json, headers: valid_headers
        book.reload

        expect(book.title).to eq("Updated Book Title")
        expect(book.authors).to include(updated_author)
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
        updated_book = Book.find(json_response["id"])

        expect(json_response["title"]).to eq("Updated Book Title")
        expect(updated_book.authors).to include(updated_author)
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
        patch book_url(id: 999_999),
              params: { book: { title: "Updated Title" } }.to_json, headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested book" do
      book = create(:book)

      expect do
        delete book_url(book), headers: valid_headers
      end.to change(Book, :count).by(-1)
    end

    it "returns no content status" do
      book = create(:book)

      delete book_url(book), headers: valid_headers

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for non-existent book" do
      delete book_url(id: 999_999), headers: valid_headers

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
                unpermitted_param: "should be ignored"
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
                id: 999_999,
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
      # Create authors first
      jane_smith = create(:author, name: "Jane Smith")
      ruby_johnson = create(:author, name: "Ruby Johnson")
      john_doe = create(:author, name: "John Doe")
      alice_brown = create(:author, name: "Alice Brown")
      bob_wilson = create(:author, name: "Bob Wilson")

      # Create books with authors using build+save to avoid validation issues
      book1 = build(:book_without_authors, title: "Ruby for Beginners", isbn: "9780123456789", status: "available")
      book1.authors = [jane_smith]
      book1.save!

      book2 = build(:book_without_authors, title: "JavaScript Fundamentals", isbn: "9780987654321", status: "borrowed", borrowed_until: 1.week.from_now)
      book2.authors = [ruby_johnson]
      book2.save!

      book3 = build(:book_without_authors, title: "Python Programming", isbn: "9781234567ruby", status: "reserved")
      book3.authors = [john_doe]
      book3.save!

      book4 = build(:book_without_authors, title: "Data Science Guide", isbn: "9780555666777", status: "available")
      book4.authors = [alice_brown]
      book4.save!

      book5 = build(:book_without_authors, title: "Advanced Ruby", isbn: "9781111222333", status: "borrowed", borrowed_until: 2.days.from_now)
      book5.authors = [bob_wilson]
      book5.save!
    end

    context "with valid search parameter" do
      it "returns books matching title search" do
        get "/books/search?filter[q]=JavaScript", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(1)

        book = json_response["books"].first
        expect(book["title"]).to eq("JavaScript Fundamentals")
        expect(book["authors"].first["name"]).to eq("Ruby Johnson")
        expect(book["isbn"]).to eq("9780987654321")
      end

      it "returns books matching author search" do
        get "/books/search?filter[q]=Smith", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(1)

        book = json_response["books"].first
        expect(book["authors"].first["name"]).to eq("Jane Smith")
        expect(book["title"]).to eq("Ruby for Beginners")
        expect(book["isbn"]).to eq("9780123456789")
      end

      it "returns books matching ISBN search" do
        get "/books/search?filter[q]=9780123456789", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(1)

        book = json_response["books"].first
        expect(book["isbn"]).to eq("9780123456789")
        expect(book["title"]).to eq("Ruby for Beginners")
        expect(book["authors"].first["name"]).to eq("Jane Smith")
      end

      it "returns books matching partial ISBN search" do
        get "/books/search?filter[q]=555666", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(1)

        book = json_response["books"].first
        expect(book["isbn"]).to eq("9780555666777")
        expect(book["title"]).to eq("Data Science Guide")
        expect(book["authors"].first["name"]).to eq("Alice Brown")
      end

      it "performs case-insensitive search" do
        get "/books/search?filter[q]=DAta", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)
        expect(json_response["books"].length).to eq(1)
      end

      it "returns partial matches" do
        get "/books/search?filter[q]=Guide", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(1)

        book = json_response["books"].first
        expect(book["title"]).to eq("Data Science Guide")
        expect(book["authors"].first["name"]).to eq("Alice Brown")
        expect(book["isbn"]).to eq("9780555666777")
      end

      it "strips surrounding double quotes from search query" do
        get '/books/search?filter[q]="Python"', headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(1)

        book = json_response["books"].first
        expect(book["title"]).to eq("Python Programming")
        expect(book["authors"].first["name"]).to eq("John Doe")
        expect(book["isbn"]).to eq("9781234567ruby")
      end

      it "strips surrounding single quotes from search query" do
        get "/books/search?filter[q]='JavaScript'", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(1)

        book = json_response["books"].first
        expect(book["title"]).to eq("JavaScript Fundamentals")
        expect(book["authors"].first["name"]).to eq("Ruby Johnson")
        expect(book["isbn"]).to eq("9780987654321")
      end

      it "returns empty array when no matches found" do
        get "/books/search?filter[q]=Nonexistent Book", headers: valid_headers

        expect(response).to be_successful
        expect(JSON.parse(response.body)["books"]).to eq([])
      end

      it "searches across multiple fields simultaneously" do
        get "/books/search?filter[q]=ruby", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(4)

        # Extract the returned books' data for easier assertions
        returned_titles = json_response["books"].pluck("title")
        returned_authors = json_response["books"].map { |book| book["authors"].first&.dig("name") }.compact
        returned_isbns = json_response["books"].pluck("isbn")

        expect(returned_titles).to include("Ruby for Beginners", "Advanced Ruby")  # "ruby" in title
        expect(returned_authors).to include("Ruby Johnson")                        # "ruby" in author
        expect(returned_isbns).to include("9781234567ruby") # "ruby" in ISBN

        expect(returned_titles).to contain_exactly("Ruby for Beginners", "Advanced Ruby", "JavaScript Fundamentals", "Python Programming")
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
        get "/books/search?filter[q]=", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response["books"].length).to eq(5) # Should return all books created in before block
      end

      it "returns all books when q parameter is only whitespace" do
        get "/books/search?filter[q]=   ", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response["books"].length).to eq(5) # Should return all books created in before block
      end
    end

    context "with response format" do
      it "returns JSON content type" do
        get "/books/search?filter[q]=JavaScript", headers: valid_headers

        expect(response).to be_successful
        expect(response.content_type).to match(a_string_including("application/json"))
      end

      it "returns complete book objects with all attributes" do
        get "/books/search?filter[q]=Ruby", headers: valid_headers

        expect(response).to be_successful

        json_response = JSON.parse(response.body)
        book = json_response["books"].first

        expect(book).to have_key("id")
        expect(book).to have_key("title")
        expect(book).to have_key("authors")
        expect(book).to have_key("isbn")
        expect(book).to have_key("published_date")
        expect(book).to have_key("status")
        expect(book).to have_key("created_at")
        expect(book).to have_key("updated_at")
      end
    end

    context "with multiple title search" do
      it "searches for multiple titles with comma separation" do
        get "/books/search?filter[title]=Ruby,JavaScript", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(3)
        titles = json_response["books"].pluck("title")
        expect(titles).to include("Ruby for Beginners", "Advanced Ruby", "JavaScript Fundamentals")
      end

      it "handles empty values in comma-separated titles" do
        get "/books/search?filter[title]=Ruby,,JavaScript,", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(3)
      end

      it "limits number of title filters" do
        many_titles = Array.new(15, "Ruby").join(",")
        get "/books/search?filter[title]=#{many_titles}", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Too many title filters")
      end
    end

    context "with multiple author search" do
      it "searches for multiple authors with comma separation" do
        get "/books/search?filter[author]=Jane Smith,Bob Wilson", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(2)
        authors = json_response["books"].map { |book| book["authors"].first["name"] }
        titles = json_response["books"].pluck("title")
        expect(authors).to include("Jane Smith", "Bob Wilson")
        expect(titles).to include("Ruby for Beginners", "Advanced Ruby")
      end

      it "limits number of author filters" do
        many_authors = Array.new(15, "Smith").join(",")
        get "/books/search?filter[author]=#{many_authors}", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Too many author filters")
      end
    end

    context "with multiple ISBN search" do
      it "searches for multiple ISBNs with comma separation" do
        get "/books/search?filter[isbn]=9780123456789,9780987654321", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(2)
        isbns = json_response["books"].pluck("isbn")
        titles = json_response["books"].pluck("title")
        expect(isbns).to include("9780123456789", "9780987654321")
        expect(titles).to include("Ruby for Beginners", "JavaScript Fundamentals")
      end

      it "limits number of ISBN filters" do
        many_isbns = Array.new(15, "123456789").join(",")
        get "/books/search?filter[isbn]=#{many_isbns}", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Too many ISBN filters")
      end
    end

    context "with status filtering" do
      it "filters books by available status" do
        get "/books/search?filter[status]=available", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(2) # Ruby for Beginners and Data Science Guide
        titles = json_response["books"].pluck("title")
        expect(titles).to include("Ruby for Beginners", "Data Science Guide")
        json_response["books"].each do |book|
          expect(book["status"]).to eq("available")
        end
      end

      it "filters books by borrowed status" do
        get "/books/search?filter[status]=borrowed", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(2) # JavaScript Fundamentals and Advanced Ruby
        titles = json_response["books"].pluck("title")
        expect(titles).to include("JavaScript Fundamentals", "Advanced Ruby")
        json_response["books"].each do |book|
          expect(book["status"]).to eq("borrowed")
        end
      end

      it "returns error for invalid status" do
        get "/books/search?filter[status]=invalid", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Invalid status")
        expect(json_response["error"]).to include("available, borrowed, reserved")
      end
    end

    context "with borrowed until date filtering" do
      it "finds books that will be available by the given date" do
        future_date = 3.days.from_now.strftime("%Y-%m-%d")
        get "/books/search?filter[borrowed_until]=#{future_date}", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        # Should find:
        # - Books not currently borrowed (borrowed_until IS NULL): Ruby for Beginners, Data Science Guide, Python Programming
        # - Books that will be returned by 3 days from now: Advanced Ruby (returns in 2 days)
        # Should NOT find: JavaScript Fundamentals (returns in 1 week > 3 days)
        expect(json_response["books"].length).to eq(4)

        titles = json_response["books"].pluck("title")
        expect(titles).to include("Ruby for Beginners", "Data Science Guide", "Python Programming", "Advanced Ruby")
        expect(titles).not_to include("JavaScript Fundamentals")
      end

      it "returns error for invalid date format" do
        get "/books/search?filter[borrowed_until]=invalid-date", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Invalid date format")
        expect(json_response["error"]).to include("YYYY-MM-DD")
      end
    end

    context "with combined search parameters" do
      it "combines title and status filters" do
        get "/books/search?filter[title]=Ruby&filter[status]=available", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(1)
        book = json_response["books"].first
        expect(book["title"]).to eq("Ruby for Beginners")
        expect(book["status"]).to eq("available")
      end

      it "combines author and status filters" do
        get "/books/search?filter[author]=Johnson&filter[status]=borrowed", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(1)
        book = json_response["books"].first
        expect(book["authors"].first["name"]).to eq("Ruby Johnson")
        expect(book["status"]).to eq("borrowed")
      end

      it "combines general search with status filter" do
        get "/books/search?filter[q]=Ruby&filter[status]=borrowed", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        # Should find JavaScript Fundamentals (author: Ruby Johnson, status: borrowed)
        # and Advanced Ruby (title contains Ruby, status: borrowed)
        expect(json_response["books"].length).to eq(2)

        titles = json_response["books"].pluck("title")
        expect(titles).to include("JavaScript Fundamentals", "Advanced Ruby")

        json_response["books"].each do |book|
          expect(book["status"]).to eq("borrowed")
        end
      end

      it "finds available books by ISBN that will be available by a given date" do
        # Use a date far in the future to ensure it includes books that will be returned by then
        future_date = 2.weeks.from_now.strftime("%Y-%m-%d")
        get "/books/search?filter[isbn]=9780987654321,9780555666777&filter[borrowed_until]=#{future_date}&filter[status]=available", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to eq(1)
        book = json_response["books"].first
        expect(book["title"]).to eq("Data Science Guide")
      end
    end

    context "with enhanced error handling" do
      it "requires at least one search parameter" do
        get "/books/search", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("At least one search parameter is required")
      end

      it "handles whitespace-only parameters gracefully" do
        get "/books/search?filter[title]=   ", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("At least one search parameter is required")
      end
    end

    context "with sorting" do
      it "sorts books by title ascending by default" do
        get "/books/search?filter[q]=", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        titles = json_response["books"].pluck("title")
        expect(titles).to eq(titles.sort)
      end

      it "sorts books by title ascending when explicitly specified" do
        get "/books/search?filter[q]=&sort=title", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        titles = json_response["books"].pluck("title")
        expect(titles).to eq(titles.sort)
      end

      it "sorts books by title descending" do
        get "/books/search?filter[q]=&sort=-title", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        titles = json_response["books"].pluck("title")
        expect(titles).to eq(titles.sort.reverse)
      end

      it "sorts books by author ascending" do
        get "/books/search?filter[q]=&sort=author", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        authors = json_response["books"].pluck("author")
        expect(authors).to eq(authors.sort)
      end

      it "sorts books by author descending" do
        get "/books/search?filter[q]=&sort=-author", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        authors = json_response["books"].pluck("author")
        expect(authors).to eq(authors.sort.reverse)
      end

      it "sorts books by status" do
        get "/books/search?filter[q]=&sort=status", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        statuses = json_response["books"].pluck("status")
        # Available (0), borrowed (1), reserved (2)
        expected_order = %w[available available borrowed borrowed reserved]
        expect(statuses).to eq(expected_order)
      end

      it "sorts books by created_at descending" do
        get "/books/search?filter[q]=&sort=-created_at", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        created_ats = json_response["books"].map { |book| Time.zone.parse(book["created_at"]) }
        expect(created_ats).to eq(created_ats.sort.reverse)
      end

      it "sorts books by multiple fields" do
        get "/books/search?filter[q]=&sort=status,title", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        # Group by status and check title ordering within each status
        grouped = json_response["books"].group_by { |book| book["status"] }

        # Available books should be sorted by title
        if grouped["available"]
          available_titles = grouped["available"].pluck("title")
          expect(available_titles).to eq(available_titles.sort)
        end

        # Borrowed books should be sorted by title
        if grouped["borrowed"]
          borrowed_titles = grouped["borrowed"].pluck("title")
          expect(borrowed_titles).to eq(borrowed_titles.sort)
        end
      end

      it "sorts books by multiple fields with mixed directions" do
        get "/books/search?filter[q]=&sort=status,-title", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        # Group by status and check title ordering within each status (desc this time)
        grouped = json_response["books"].group_by { |book| book["status"] }

        # Available books should be sorted by title descending
        if grouped["available"]
          available_titles = grouped["available"].pluck("title")
          expect(available_titles).to eq(available_titles.sort.reverse)
        end

        # Borrowed books should be sorted by title descending
        if grouped["borrowed"]
          borrowed_titles = grouped["borrowed"].pluck("title")
          expect(borrowed_titles).to eq(borrowed_titles.sort.reverse)
        end
      end

      it "returns error for invalid sort field" do
        get "/books/search?filter[q]=&sort=invalid_field", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Invalid sort field: invalid_field")
        expect(json_response["error"]).to include("Valid fields are: title, author, isbn, published_date, status, borrowed_until, created_at, updated_at")
      end

      it "returns error for invalid sort field in multiple field sort" do
        get "/books/search?filter[q]=&sort=title,invalid_field,author", headers: valid_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Invalid sort field: invalid_field")
      end

      it "sorts filtered results" do
        get "/books/search?filter[q]=Ruby&sort=title", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response["books"].length).to be > 1
        titles = json_response["books"].pluck("title")
        expect(titles).to eq(titles.sort)
      end
    end

    context "with pagination" do
      before do
        # Create additional books for pagination testing (we already have 5 from the main before block)
        6.upto(15) do |i|
          author = create(:author, name: "Author #{i}")
          book = build(:book_without_authors, title: "Book #{i.to_s.rjust(2, '0')}", isbn: "97801234567#{i.to_s.rjust(2, '0')}", status: "available")
          book.authors = [author]
          book.save!
        end
      end

      it "returns paginated results with default pagination (page 1, 20 per page)" do
        get "/books/search?filter[q]=", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(json_response).to have_key("books")
        expect(json_response).to have_key("pagination")

        books = json_response["books"]
        pagination = json_response["pagination"]

        expect(books.length).to eq(15) # All 15 books fit on first page
        expect(pagination["current_page"]).to eq(1)
        expect(pagination["per_page"]).to eq(20)
        expect(pagination["total_count"]).to eq(15)
        expect(pagination["total_pages"]).to eq(1)
        expect(pagination["has_next_page"]).to be false
        expect(pagination["has_previous_page"]).to be false
      end

      it "returns first page with custom per_page" do
        get "/books/search?filter[q]=&page=1&per_page=5", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        books = json_response["books"]
        pagination = json_response["pagination"]

        expect(books.length).to eq(5)
        expect(pagination["current_page"]).to eq(1)
        expect(pagination["per_page"]).to eq(5)
        expect(pagination["total_count"]).to eq(15)
        expect(pagination["total_pages"]).to eq(3)
        expect(pagination["has_next_page"]).to be true
        expect(pagination["has_previous_page"]).to be false
      end

      it "returns second page with custom per_page" do
        get "/books/search?filter[q]=&page=2&per_page=5", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        books = json_response["books"]
        pagination = json_response["pagination"]

        expect(books.length).to eq(5)
        expect(pagination["current_page"]).to eq(2)
        expect(pagination["per_page"]).to eq(5)
        expect(pagination["total_count"]).to eq(15)
        expect(pagination["total_pages"]).to eq(3)
        expect(pagination["has_next_page"]).to be true
        expect(pagination["has_previous_page"]).to be true
      end

      it "returns last page with correct number of items" do
        get "/books/search?filter[q]=&page=3&per_page=5", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        books = json_response["books"]
        pagination = json_response["pagination"]

        expect(books.length).to eq(5) # 15 total / 5 per page = 3 full pages
        expect(pagination["current_page"]).to eq(3)
        expect(pagination["per_page"]).to eq(5)
        expect(pagination["total_count"]).to eq(15)
        expect(pagination["total_pages"]).to eq(3)
        expect(pagination["has_next_page"]).to be false
        expect(pagination["has_previous_page"]).to be true
      end

      it "returns empty page beyond last page" do
        get "/books/search?filter[q]=&page=4&per_page=5", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        books = json_response["books"]
        pagination = json_response["pagination"]

        expect(books.length).to eq(0)
        expect(pagination["current_page"]).to eq(4)
        expect(pagination["per_page"]).to eq(5)
        expect(pagination["total_count"]).to eq(15)
        expect(pagination["total_pages"]).to eq(3)
        expect(pagination["has_next_page"]).to be false
        expect(pagination["has_previous_page"]).to be true
      end

      it "works with filtered results" do
        get "/books/search?filter[q]=Book&page=2&per_page=3", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        books = json_response["books"]
        pagination = json_response["pagination"]

        # Should find 10 books with "Book" in title (Book 06 through Book 15)
        expect(books.length).to eq(3)
        expect(pagination["current_page"]).to eq(2)
        expect(pagination["per_page"]).to eq(3)
        expect(pagination["total_count"]).to eq(10)
        expect(pagination["total_pages"]).to eq(4) # 10/3 = 3.33 rounded up to 4
        expect(pagination["has_next_page"]).to be true
        expect(pagination["has_previous_page"]).to be true
      end

      it "works with sorting and pagination" do
        get "/books/search?filter[q]=&sort=-title&page=1&per_page=3", headers: valid_headers

        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        books = json_response["books"]
        pagination = json_response["pagination"]

        expect(books.length).to eq(3)
        expect(pagination["current_page"]).to eq(1)
        expect(pagination["per_page"]).to eq(3)
        expect(pagination["total_count"]).to eq(15)

        # Check that results are actually sorted descending by title
        titles = books.pluck("title")
        expect(titles).to eq(titles.sort.reverse)
      end

      context "with pagination parameter validation" do
        it "returns error for page less than 1" do
          get "/books/search?filter[q]=&page=0", headers: valid_headers

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Page must be 1 or greater")
        end

        it "returns error for negative page" do
          get "/books/search?filter[q]=&page=-1", headers: valid_headers

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Page must be 1 or greater")
        end

        it "returns error for per_page less than 1" do
          get "/books/search?filter[q]=&per_page=0", headers: valid_headers

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Per page must be between 1 and 100")
        end

        it "returns error for per_page greater than 100" do
          get "/books/search?filter[q]=&per_page=101", headers: valid_headers

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Per page must be between 1 and 100")
        end

        it "accepts maximum per_page of 100" do
          get "/books/search?filter[q]=&per_page=100", headers: valid_headers

          expect(response).to be_successful
          json_response = JSON.parse(response.body)
          expect(json_response["pagination"]["per_page"]).to eq(100)
        end

        it "accepts minimum per_page of 1" do
          get "/books/search?filter[q]=&per_page=1", headers: valid_headers

          expect(response).to be_successful
          json_response = JSON.parse(response.body)
          expect(json_response["pagination"]["per_page"]).to eq(1)
          expect(json_response["books"].length).to eq(1)
        end
      end

      context "with pagination when no results" do
        it "returns correct pagination metadata when no books match filter" do
          get "/books/search?filter[q]=NonexistentBook&page=1&per_page=10", headers: valid_headers

          expect(response).to be_successful
          json_response = JSON.parse(response.body)

          books = json_response["books"]
          pagination = json_response["pagination"]

          expect(books.length).to eq(0)
          expect(pagination["current_page"]).to eq(1)
          expect(pagination["per_page"]).to eq(10)
          expect(pagination["total_count"]).to eq(0)
          expect(pagination["total_pages"]).to eq(0)
          expect(pagination["has_next_page"]).to be false
          expect(pagination["has_previous_page"]).to be false
        end
      end

      context "with response format with pagination" do
        it "returns correct response structure" do
          get "/books/search?filter[q]=&page=1&per_page=5", headers: valid_headers

          expect(response).to be_successful
          json_response = JSON.parse(response.body)

          # Check top-level structure
          expect(json_response).to have_key("books")
          expect(json_response).to have_key("pagination")

          # Check books array structure
          expect(json_response["books"]).to be_an(Array)
          expect(json_response["books"].length).to eq(5)

          # Check pagination object structure
          pagination = json_response["pagination"]
          expect(pagination).to have_key("current_page")
          expect(pagination).to have_key("per_page")
          expect(pagination).to have_key("total_count")
          expect(pagination).to have_key("total_pages")
          expect(pagination).to have_key("has_next_page")
          expect(pagination).to have_key("has_previous_page")

          # Check that all pagination values are correct types
          expect(pagination["current_page"]).to be_an(Integer)
          expect(pagination["per_page"]).to be_an(Integer)
          expect(pagination["total_count"]).to be_an(Integer)
          expect(pagination["total_pages"]).to be_an(Integer)
          expect(pagination["has_next_page"]).to be_in([true, false])
          expect(pagination["has_previous_page"]).to be_in([true, false])
        end

        it "returns complete book objects in paginated results" do
          get "/books/search?filter[q]=&page=1&per_page=3", headers: valid_headers

          expect(response).to be_successful
          json_response = JSON.parse(response.body)

          book = json_response["books"].first

          expect(book).to have_key("id")
          expect(book).to have_key("title")
          expect(book).to have_key("authors")
          expect(book).to have_key("isbn")
          expect(book).to have_key("published_date")
          expect(book).to have_key("status")
          expect(book).to have_key("created_at")
          expect(book).to have_key("updated_at")
        end
      end

      context "with edge cases" do
        it "handles non-integer page parameter gracefully" do
          get "/books/search?filter[q]=&page=abc", headers: valid_headers

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Page must be 1 or greater")
        end

        it "handles non-integer per_page parameter gracefully" do
          get "/books/search?filter[q]=&per_page=xyz", headers: valid_headers

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Per page must be between 1 and 100")
        end

        it "handles float page parameter by converting to integer" do
          get "/books/search?filter[q]=&page=2.7", headers: valid_headers

          expect(response).to be_successful
          json_response = JSON.parse(response.body)
          expect(json_response["pagination"]["current_page"]).to eq(2)
        end

        it "handles float per_page parameter by converting to integer" do
          get "/books/search?filter[q]=&per_page=5.9", headers: valid_headers

          expect(response).to be_successful
          json_response = JSON.parse(response.body)
          expect(json_response["pagination"]["per_page"]).to eq(5)
        end
      end

      context "with consistency across pages" do
        it "maintains consistent sorting and prevents duplicates across paginated results" do
          # Get first page
          get "/books/search?filter[q]=&sort=title&page=1&per_page=5", headers: valid_headers
          expect(response).to be_successful
          page1_response = JSON.parse(response.body)
          page1_titles = page1_response["books"].pluck("title")

          # Get second page
          get "/books/search?filter[q]=&sort=title&page=2&per_page=5", headers: valid_headers
          expect(response).to be_successful
          page2_response = JSON.parse(response.body)
          page2_titles = page2_response["books"].pluck("title")

          # Get third page
          get "/books/search?filter[q]=&sort=title&page=3&per_page=5", headers: valid_headers
          expect(response).to be_successful
          page3_response = JSON.parse(response.body)
          page3_titles = page3_response["books"].pluck("title")

          all_titles = page1_titles + page2_titles + page3_titles

          expect(all_titles).to eq(all_titles.sort)
          expect(all_titles.uniq.length).to eq(all_titles.length)
        end
      end
    end
  end
end
