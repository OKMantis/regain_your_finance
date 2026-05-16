class CreateLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :line_items do |t|
      t.string :name
      t.integer :category
      t.integer :amount_cents
      t.integer :billing_period
      t.string :payment_method
      t.integer :amount_cents_monthly
      t.references :property, null: true, foreign_key: true

      t.timestamps
    end
  end
end
