class BooksController < ApplicationController
  before_action :set_book, only: %i[ show update destroy ]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :bad_request

  # GET /books
  # GET /books.json
  def index
    @books = Book.includes(:authors).order(:id)

    # Custom JSON with authors sorted by name
    books_json = @books.map do |book|
      book.as_json.merge(
        'authors' => book.authors_sorted_by_name.as_json(except: [:created_at, :updated_at])
      )
    end

    render json: books_json
  end

  # GET /books/1
  # GET /books/1.json
  def show
    book_json = @book.as_json.merge(
      'authors' => @book.authors_sorted_by_name.as_json(except: [:created_at, :updated_at])
    )

    render json: book_json
  end

  # POST /books
  # POST /books.json
  def create
    @book = Book.new(book_params)

    if @book.save
      render json: @book, include: :authors, status: :created, location: @book
    else
      render json: @book.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /books/1
  # PATCH/PUT /books/1.json
  def update
    if @book.update(book_params)
      render json: @book, include: :authors, status: :ok
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

    # FILTERS
    return render_missing_filter_error unless params[:filter].present?

    @has_q_filter = apply_q_filter

    return if error_applying_title_filter?
    return if error_applying_author_filter?
    return if error_applying_isbn_filter?
    return if error_applying_status_filter?
    return if error_applying_borrowed_until_filter?

    return unless validate_at_least_one_filter

    # SORTING

    # Apply sorting if sort parameter is provided
    if params[:sort].present?
      sort_fields = params[:sort].split(',').map(&:strip)

      # Validate each sort field
      sort_criteria = []

      needs_author_join = false

      sort_fields.each do |field|
        direction = 'ASC'
        column = field

        # Handle descending order (prefix with -)
        if field.start_with?('-')
          direction = 'DESC'
          column = field[1..]
        end

        # Validate column name
        valid_columns = ['title', 'author', 'isbn', 'published_date', 'status', 'borrowed_until', 'created_at', 'updated_at']
        unless valid_columns.include?(column)
          return render json: { error: "Invalid sort field: #{column}. Valid fields are: #{valid_columns.join(', ')}" }, status: :bad_request
        end

        # Handle author sorting specially
        if column == 'author'
          # Use a subquery to get the first author name for each book for sorting
          # This avoids the DISTINCT + ORDER BY issues with PostgreSQL
          sort_criteria << Arel.sql("(SELECT authors.name FROM authors INNER JOIN authors_books ON authors.id = authors_books.author_id WHERE authors_books.book_id = books.id ORDER BY authors.name LIMIT 1) #{direction}")
        else
          sort_criteria << "#{column} #{direction}"
        end
      end

      @books = @books.order(sort_criteria)
    else
      # Default sorting by title ASC for search endpoint
      @books = @books.order(:title)
    end

    # PAGINATION

    page = params[:page].present? ? params[:page].to_i : 1
    per_page = params[:per_page].present? ? params[:per_page].to_i : 20

    # Validate pagination parameters
    if page < 1
      return render json: { error: "Page must be 1 or greater" }, status: :bad_request
    end

    if per_page < 1 || per_page > 100
      return render json: { error: "Per page must be between 1 and 100" }, status: :bad_request
    end

    offset = (page - 1) * per_page
    total_count = @books.count
    @books = @books.limit(per_page).offset(offset)

    # Eager load authors for JSON serialization to avoid N+1
    @books = @books.includes(:authors)

    # Calculate pagination metadata
    total_pages = total_count == 0 ? 0 : (total_count.to_f / per_page).ceil

    # Prepare response with pagination metadata
    books_with_sorted_authors = @books.map do |book|
      book.as_json.merge(
        'authors' => book.authors_sorted_by_name.as_json(except: [:created_at, :updated_at])
      )
    end

    response_data = {
      books: books_with_sorted_authors,
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages,
        has_next_page: page < total_pages,
        has_previous_page: page > 1
      }
    }

    render json: response_data
  end

  private
    def set_book
      @book = Book.find(params[:id])
    end

    def book_params
      params.require(:book).permit(:title, :isbn, :published_date, :status, :borrowed_until, author_ids: [])
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

    # Filter-related private methods
    def render_missing_filter_error
      render json: { error: "At least one search parameter is required" }, status: :bad_request
    end

    def apply_q_filter
      return false unless params.dig(:filter, :q).present?

      clean_query = params.dig(:filter, :q).gsub(/^["']|["']$/, '').strip

      if clean_query.present?
        @books = @books.joins(:authors).where(
          "title ILIKE ? OR authors.name ILIKE ? OR isbn ILIKE ?",
          "%#{clean_query}%", "%#{clean_query}%", "%#{clean_query}%"
        ).distinct
        return true
      end

      false
    end

    def error_applying_title_filter?
      return false unless params.dig(:filter, :title).present?

      titles = params.dig(:filter, :title).split(',').map(&:strip).reject(&:blank?)

      if titles.empty?
        render_missing_filter_error
        return true
      end

      unless validate_filter_count(titles, "title")
        return true
      end

      if titles.any?
        title_conditions = titles.map { "title ILIKE ?" }.join(' OR ')
        title_values = titles.map { |title| "%#{title}%" }
        @books = @books.where(title_conditions, *title_values)
      end

      false
    end

    def error_applying_author_filter?
      return false unless params.dig(:filter, :author).present?

      authors = params.dig(:filter, :author).split(',').map(&:strip).reject(&:blank?)

      if authors.empty?
        render_missing_filter_error
        return true
      end

      unless validate_filter_count(authors, "author")
        return true
      end

      if authors.any?
        author_conditions = authors.map { "authors.name ILIKE ?" }.join(' OR ')
        author_values = authors.map { |author| "%#{author}%" }
        @books = @books.joins(:authors).where(author_conditions, *author_values).distinct
      end

      false
    end

    def error_applying_isbn_filter?
      return false unless params.dig(:filter, :isbn).present?

      isbns = params.dig(:filter, :isbn).split(',').map(&:strip).reject(&:blank?)

      if isbns.empty?
        render_missing_filter_error
        return true
      end

      unless validate_filter_count(isbns, "ISBN")
        return true
      end

      if isbns.any?
        isbn_conditions = isbns.map { "isbn ILIKE ?" }.join(' OR ')
        isbn_values = isbns.map { |isbn| "%#{isbn}%" }
        @books = @books.where(isbn_conditions, *isbn_values)
      end

      false
    end

    def error_applying_status_filter?
      return false unless params.dig(:filter, :status).present?

      valid_statuses = ['available', 'borrowed', 'reserved']
      if valid_statuses.include?(params.dig(:filter, :status))
        @books = @books.where(status: params.dig(:filter, :status))
      else
        render json: { error: "Invalid status. Must be: #{valid_statuses.join(', ')}" }, status: :bad_request
        return true
      end

      false
    end

    def error_applying_borrowed_until_filter?
      return false unless params.dig(:filter, :borrowed_until).present?

      begin
        borrowed_until_date = Date.parse(params.dig(:filter, :borrowed_until))
        @books = @books.where("borrowed_until IS NULL OR borrowed_until <= ?", borrowed_until_date)
      rescue ArgumentError
        render json: { error: "Invalid date format. Please use YYYY-MM-DD." }, status: :bad_request
        return true
      end

      false
    end

    def validate_at_least_one_filter
      other_params = [:title, :author, :isbn, :status, :borrowed_until]
      has_other_filters = other_params.any? { |param| params.dig(:filter, param).present? }

      # Check if q parameter exists at all (even if empty/whitespace)
      has_q_param = params[:filter] && params[:filter].key?(:q)

      # Only return error if no filters at all AND no q parameter (even empty ones)
      if !@has_q_filter && !has_other_filters && !has_q_param
        render json: { error: "At least one search parameter is required" }, status: :bad_request
        return false
      end

      true
    end
end
