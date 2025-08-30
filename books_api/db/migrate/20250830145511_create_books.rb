class CreateBooks < ActiveRecord::Migration[7.0]
  def change
    create_table :books do |t|
      t.string :title
      t.string :author
      t.integer :isbn
      t.datetime :published_date
      t.integer :status, default: 0
      t.datetime :borrowed_until

      t.timestamps
    end
  end
end
