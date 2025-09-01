# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Books API V1",
        version: "v1",
        description: "A simple library management API for managing books and authors",
        contact: {
          name: "API Support",
          email: "support@example.com"
        }
      },
      paths: {},
      servers: [
        {
          url: "http://localhost:3001",
          description: "Development server"
        }
      ],
      components: {
        schemas: {
          Book: {
            type: "object",
            properties: {
              id: { type: "integer", example: 1 },
              title: { type: "string", example: "The Great Gatsby" },
              isbn: { type: "string", example: "978-0-7432-7356-5" },
              published_date: { type: "string", format: "date", example: "1925-04-10" },
              status: {
                type: "string",
                enum: %w[available borrowed reserved],
                example: "available"
              },
              borrowed_until: {
                type: "string",
                format: "date",
                nullable: true,
                example: "2023-12-31"
              },
              created_at: { type: "string", format: "date-time" },
              updated_at: { type: "string", format: "date-time" },
              authors: {
                type: "array",
                items: { "$ref" => "#/components/schemas/Author" }
              }
            },
            required: %w[id title isbn status created_at updated_at authors]
          },
          Author: {
            type: "object",
            properties: {
              id: { type: "integer", example: 1 },
              name: { type: "string", example: "F. Scott Fitzgerald" }
            },
            required: %w[id name]
          },
          BookInput: {
            type: "object",
            properties: {
              title: { type: "string", example: "The Great Gatsby" },
              isbn: { type: "string", example: "978-0-7432-7356-5" },
              published_date: { type: "string", format: "date", example: "1925-04-10" },
              status: {
                type: "string",
                enum: %w[available borrowed reserved],
                example: "available"
              },
              borrowed_until: {
                type: "string",
                format: "date",
                nullable: true,
                example: "2023-12-31"
              },
              author_ids: {
                type: "array",
                items: { type: "integer" },
                example: [1, 2]
              }
            },
            required: %w[title isbn status]
          },
          SearchResponse: {
            type: "object",
            properties: {
              books: {
                type: "array",
                items: { "$ref" => "#/components/schemas/Book" }
              },
              pagination: { "$ref" => "#/components/schemas/Pagination" }
            },
            required: %w[books pagination]
          },
          Pagination: {
            type: "object",
            properties: {
              current_page: { type: "integer", example: 1 },
              per_page: { type: "integer", example: 20 },
              total_count: { type: "integer", example: 100 },
              total_pages: { type: "integer", example: 5 },
              has_next_page: { type: "boolean", example: true },
              has_previous_page: { type: "boolean", example: false }
            },
            required: %w[current_page per_page total_count total_pages has_next_page has_previous_page]
          },
          Error: {
            type: "object",
            properties: {
              error: { type: "string", example: "Record not found" }
            },
            required: ["error"]
          },
          ValidationError: {
            type: "object",
            properties: {
              title: {
                type: "array",
                items: { type: "string" },
                example: ["can't be blank"]
              }
            }
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
