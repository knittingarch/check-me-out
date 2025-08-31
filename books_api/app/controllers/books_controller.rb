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
    query = params[:q]

    if query.present?
      # Strip any surrounding quotes that might be included in the parameter
      clean_query = query.gsub(/^["']|["']$/, '')

      @books = Book.where(
        "title ILIKE ? OR author ILIKE ? OR isbn ILIKE ?",
        "%#{clean_query}%", "%#{clean_query}%", "%#{clean_query}%"
      )

      render json: @books
    else
      render json: { error: "Search query parameter is required" }, status: :bad_request
    end
  end

  private
    def set_book
      @book = Book.find(params[:id])
    end

    def book_params
      params.require(:book).permit(:title, :author, :isbn, :published_date, :status, :borrowed_until)
    end

    def record_not_found
      render json: { error: 'Record not found' }, status: :not_found
    end

    def bad_request
      render json: { error: 'Bad request' }, status: :bad_request
    end
end
