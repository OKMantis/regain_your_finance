class CreateSpendingCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :spending_categories do |t|
      t.string  :name,                 null: false
      t.integer :weekly_target_cents
      t.integer :monthly_target_cents
      t.timestamps
    end
    add_index :spending_categories, :name, unique: true
  end
end
