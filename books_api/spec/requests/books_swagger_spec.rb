# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Books API', type: :request do
  # Sample data setup
  let!(:author1) { create(:author, name: 'F. Scott Fitzgerald') }
  let!(:author2) { create(:author, name: 'Harper Lee') }
  let!(:book1) { create(:book, title: 'The Great Gatsby', isbn: '978-0-7432-7356-5', status: 'available', authors: [author1]) }
  let!(:book2) { create(:book, title: 'To Kill a Mockingbird', isbn: '978-0-06-112008-4', status: 'borrowed', authors: [author2]) }

  path '/books' do
    get 'Retrieves all books' do
      tags 'Books'
      description 'Returns a list of all books in the library with their associated authors'
      produces 'application/json'

      response '200', 'books found' do
        schema type: :array,
               items: { '$ref' => '#/components/schemas/Book' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.length).to eq(2)
          expect(data.first).to have_key('title')
          expect(data.first).to have_key('authors')
          expect(data.first['authors']).to be_an(Array)
        end
      end
    end

    post 'Creates a book' do
      tags 'Books'
      description 'Creates a new book in the library'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :book, in: :body, schema: {
        type: :object,
        properties: {
          book: { '$ref' => '#/components/schemas/BookInput' }
        },
        required: ['book']
      }

      response '201', 'book created' do
        schema '$ref' => '#/components/schemas/Book'

        let(:book) do
          {
            book: {
              title: 'New Book',
              isbn: '978-1-234-56789-0',
              published_date: '2023-01-01',
              status: 'available',
              author_ids: [author1.id]
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['title']).to eq('New Book')
          expect(data['isbn']).to eq('978-1-234-56789-0')
        end
      end

      response '422', 'invalid request' do
        schema '$ref' => '#/components/schemas/ValidationError'

        let(:book) do
          {
            book: {
              title: '',
              isbn: '',
              status: 'invalid_status'
            }
          }
        end

        run_test!
      end
    end
  end

  path '/books/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Book ID'

    get 'Retrieves a book' do
      tags 'Books'
      description 'Returns a specific book by ID with its associated authors'
      produces 'application/json'

      response '200', 'book found' do
        schema '$ref' => '#/components/schemas/Book'

        let(:id) { book1.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['id']).to eq(book1.id)
          expect(data['title']).to eq(book1.title)
          expect(data['authors']).to be_an(Array)
        end
      end

      response '404', 'book not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 999999 }
        run_test!
      end
    end

    put 'Updates a book' do
      tags 'Books'
      description 'Updates an existing book'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :book, in: :body, schema: {
        type: :object,
        properties: {
          book: { '$ref' => '#/components/schemas/BookInput' }
        },
        required: ['book']
      }

      response '200', 'book updated' do
        schema '$ref' => '#/components/schemas/Book'

        let(:id) { book1.id }
        let(:book) do
          {
            book: {
              title: 'Updated Title',
              status: 'borrowed'
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['title']).to eq('Updated Title')
          expect(data['status']).to eq('borrowed')
        end
      end

      response '404', 'book not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 999999 }
        let(:book) { { book: { title: 'Updated Title' } } }
        run_test!
      end

      response '422', 'invalid request' do
        schema '$ref' => '#/components/schemas/ValidationError'
        let(:id) { book1.id }
        let(:book) { { book: { title: '', status: 'invalid_status' } } }
        run_test!
      end
    end

    delete 'Deletes a book' do
      tags 'Books'
      description 'Deletes a book from the library'

      response '204', 'book deleted' do
        let(:id) { book1.id }
        run_test! do |response|
          expect(response.body).to be_empty
        end
      end

      response '404', 'book not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 999999 }
        run_test!
      end
    end
  end

  path '/books/search' do
    get 'Search books' do
      tags 'Books'
      description 'Search books with various filters, sorting, and pagination'
      produces 'application/json'

      parameter name: :filter, in: :query, type: :object, style: :deepObject, explode: true, schema: {
        type: :object,
        properties: {
          q: { 
            type: :string, 
            description: 'General search query (searches title, author, and ISBN)',
            example: 'gatsby'
          },
          title: { 
            type: :string, 
            description: 'Filter by book title (comma-separated for multiple)',
            example: 'gatsby,mockingbird'
          },
          author: { 
            type: :string, 
            description: 'Filter by author name (comma-separated for multiple)',
            example: 'fitzgerald,lee'
          },
          isbn: { 
            type: :string, 
            description: 'Filter by ISBN (comma-separated for multiple)',
            example: '978-0-7432-7356-5'
          },
          status: { 
            type: :string, 
            enum: ['available', 'borrowed', 'reserved'],
            description: 'Filter by book status'
          },
          borrowed_until: { 
            type: :string, 
            format: :date,
            description: 'Filter books available before this date (YYYY-MM-DD)',
            example: '2023-12-31'
          }
        }
      }

      parameter name: :sort, in: :query, type: :string, description: 'Sort fields (comma-separated, prefix with - for descending)', example: 'title,-published_date'
      parameter name: :page, in: :query, type: :integer, description: 'Page number (default: 1)', example: 1
      parameter name: :per_page, in: :query, type: :integer, description: 'Results per page (1-100, default: 20)', example: 20

      response '200', 'search results' do
        schema '$ref' => '#/components/schemas/SearchResponse'

        # Test basic search
        context 'with basic search query' do
          let(:filter) { { q: 'gatsby' } }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data).to have_key('books')
            expect(data).to have_key('pagination')
            expect(data['books']).to be_an(Array)
            expect(data['pagination']).to include('current_page', 'per_page', 'total_count')
          end
        end

        # Test title filter
        context 'with title filter' do
          let(:filter) { { title: 'gatsby' } }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['books'].first['title']).to include('Gatsby')
          end
        end

        # Test author filter
        context 'with author filter' do
          let(:filter) { { author: 'fitzgerald' } }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['books'].first['authors'].first['name']).to include('Fitzgerald')
          end
        end

        # Test status filter
        context 'with status filter' do
          let(:filter) { { status: 'available' } }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['books'].all? { |book| book['status'] == 'available' }).to be true
          end
        end

        # Test sorting
        context 'with sorting' do
          let(:filter) { { q: '' } }
          let(:sort) { 'title' }

          run_test! do |response|
            data = JSON.parse(response.body)
            titles = data['books'].map { |book| book['title'] }
            expect(titles).to eq(titles.sort)
          end
        end

        # Test pagination
        context 'with pagination' do
          let(:filter) { { q: '' } }
          let(:page) { 1 }
          let(:per_page) { 1 }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data['books'].length).to eq(1)
            expect(data['pagination']['per_page']).to eq(1)
            expect(data['pagination']['current_page']).to eq(1)
          end
        end
      end

      response '400', 'bad request' do
        schema '$ref' => '#/components/schemas/Error'

        context 'without any filter parameters' do
          run_test!
        end

        context 'with invalid status' do
          let(:filter) { { status: 'invalid_status' } }
          run_test!
        end

        context 'with invalid date format' do
          let(:filter) { { borrowed_until: 'invalid-date' } }
          run_test!
        end

        context 'with invalid page number' do
          let(:filter) { { q: '' } }
          let(:page) { 0 }
          run_test!
        end

        context 'with invalid per_page number' do
          let(:filter) { { q: '' } }
          let(:per_page) { 101 }
          run_test!
        end

        context 'with invalid sort field' do
          let(:filter) { { q: '' } }
          let(:sort) { 'invalid_field' }
          run_test!
        end
      end
    end
  end
end
