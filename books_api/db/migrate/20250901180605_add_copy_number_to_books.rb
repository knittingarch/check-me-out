class AddCopyNumberToBooks < ActiveRecord::Migration[7.1]
  def change
    add_column :books, :copy_number, :integer, null: false, default: 1
  end
end
