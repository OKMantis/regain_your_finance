class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      t.string :name
      t.integer :ownership_percentage

      t.timestamps
    end
  end
end
