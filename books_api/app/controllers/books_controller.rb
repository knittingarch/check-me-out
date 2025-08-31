class BooksController < ApplicationController
  before_action :set_book, only: %i[ show update destroy ]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :bad_request

  # GET /books
# GET /books.json
  def index
    @books = Book.all

    render json: @books
  end

  # GET /books/1
  # GET /books/1.json
  def show
    render json: @book
  end

  # POST /books
  # POST /books.json
  def create
    @book = Book.new(book_params)

    if @book.save
      render json: @book, status: :created, location: @book
    else
      render json: @book.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /books/1
  # PATCH/PUT /books/1.json
  def update
    if @book.update(book_params)
      render json: @book, status: :ok
    else
      render json: @book.errors, status: :unprocessable_entity
    end
  end

  # DELETE /books/1
  # DELETE /books/1.json
  def destroy
    @book.destroy
    head :no_content
  end

  def search
    @books = Book.all

    has_q_filter = false
    if params[:q].present?
      clean_query = params[:q].gsub(/^["']|["']$/, '').strip

      # Only apply the filter if there's actually content after cleaning
      if clean_query.present?
        @books = @books.where(
          "title ILIKE ? OR author ILIKE ? OR isbn ILIKE ?",
          "%#{clean_query}%", "%#{clean_query}%", "%#{clean_query}%"
        )
        has_q_filter = true
      end
    end

    # Search by multiple titles
    if params[:title].present?
     titles = params[:title].split(',').map(&:strip).reject(&:blank?)

      # Limit number of titles to prevent abuse
      return unless validate_filter_count(titles, "title")

      if titles.any?
        title_conditions = titles.map { "title ILIKE ?" }.join(' OR ')
        title_values = titles.map { |title| "%#{title}%" }
        @books = @books.where(title_conditions, *title_values)
      end
    end

    # Search by multiple authors
    if params[:author].present?
      authors = params[:author].split(',').map(&:strip).reject(&:blank?)

      return unless validate_filter_count(authors, "author")

      if authors.any?
        author_conditions = authors.map { "author ILIKE ?" }.join(' OR ')
        author_values = authors.map { |author| "%#{author}%" }
        @books = @books.where(author_conditions, *author_values)
      end
    end

    # Search by multiple ISBNS
    if params[:isbn].present?
      isbns = params[:isbn].split(',').map(&:strip).reject(&:blank?)

      return unless validate_filter_count(isbns, "ISBN")

      if isbns.any?
        isbn_conditions = isbns.map { "isbn ILIKE ?" }.join(' OR ')
        isbn_values = isbns.map { |isbn| "%#{isbn}%" }
        @books = @books.where(isbn_conditions, *isbn_values)
      end
    end

    # Filter by Status
    if params[:status].present?
      valid_statuses = ['available', 'borrowed', 'reserved']
      if valid_statuses.include?(params[:status])
        @books = @books.where(status: params[:status])
      else
        return render json: { error: "Invalid status. Must be: #{valid_statuses.join(', ')}" }, status: :bad_request
      end
    end

    # Filter by Borrowed Until Date
    if params[:borrowed_until].present?
      begin
        borrowed_until_date = Date.parse(params[:borrowed_until])

        @books = @books.where("borrowed_until IS NULL OR borrowed_until <= ?", borrowed_until_date)
      rescue ArgumentError
        return render json: { error: "Invalid date format. Please use YYYY-MM-DD." }, status: :bad_request
      end
    end

    # Check if any meaningful search criteria was provided
    other_params = [:title, :author, :isbn, :status, :borrowed_until]
    has_other_filters = other_params.any? { |param| params[param].present? }

    # Allow empty/whitespace q parameter to return all books
    has_empty_q = params.key?(:q) && params[:q].gsub(/^["']|["']$/, '').strip.blank?

    if !has_q_filter && !has_other_filters && !has_empty_q
      return render json: { error: "At least one search parameter is required" }, status: :bad_request
    end

    render json: @books
  end

  private
    def set_book
      @book = Book.find(params[:id])
    end

    def book_params
      params.require(:book).permit(:title, :author, :isbn, :published_date, :status, :borrowed_until)
    end

    def validate_filter_count(values, filter_type, max_count = 10)
      if values.length > max_count
        render json: { error: "Too many #{filter_type} filters. Maximum #{max_count} allowed." }, status: :bad_request
        return false
      end
      true
    end

    def record_not_found
      render json: { error: 'Record not found' }, status: :not_found
    end

    def bad_request
      render json: { error: 'Bad request' }, status: :bad_request
    end
end
