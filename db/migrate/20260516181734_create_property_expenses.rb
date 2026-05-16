class CreatePropertyExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :property_expenses do |t|
      t.references :property, null: false, foreign_key: true
      t.string :name
      t.integer :category
      t.integer :amount_cents
      t.integer :billing_period
      t.integer :amount_cents_monthly

      t.timestamps
    end
  end
end
