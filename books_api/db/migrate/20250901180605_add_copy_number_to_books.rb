class AddCopyNumberToBooks < ActiveRecord::Migration[7.1]
  def change
    add_column :books, :copy_number, :integer, null: false, default: 1

    # Add a unique constraint to ensure no duplicate copy numbers for the same book
    add_index :books, [:title, :isbn, :copy_number], unique: true, name: 'index_books_on_title_isbn_copy_number'
  end
end
