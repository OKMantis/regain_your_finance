class CreateSpendingEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :spending_entries do |t|
      t.references :spending_category, null: false, foreign_key: true
      t.integer    :amount_cents,      null: false
      t.string     :description
      t.date       :spent_on,          null: false
      t.timestamps
    end
    add_index :spending_entries, :spent_on
    add_index :spending_entries, [:spending_category_id, :spent_on]
  end
end
