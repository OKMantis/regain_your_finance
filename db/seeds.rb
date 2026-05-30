LineItem.destroy_all
PropertyExpense.destroy_all
Property.destroy_all

# ── Properties ────────────────────────────────────────────────────────────────

downtown = Property.create!(name: "Downtown Apartment", ownership_percentage: 100)
lakeside  = Property.create!(name: "Lakeside Studio",   ownership_percentage: 100)
westend   = Property.create!(name: "West End Flat",     ownership_percentage: 100)

# ── Property expenses ─────────────────────────────────────────────────────────

[
  { property: downtown, name: "Mortgage",        category: :mortgage,    amount_cents: 95_000,  billing_period: :monthly },
  { property: downtown, name: "Home insurance",  category: :insurance,   amount_cents: 48_000,  billing_period: :yearly },
  { property: downtown, name: "Life insurance",  category: :insurance,   amount_cents: 22_000,  billing_period: :yearly },
  { property: downtown, name: "Property tax",    category: :tax,         amount_cents: 12_000,  billing_period: :yearly },
  { property: downtown, name: "HOA fees",        category: :community,   amount_cents: 18_000,  billing_period: :monthly },
  { property: downtown, name: "Contingency",     category: :contingency, amount_cents:  5_000,  billing_period: :monthly },

  { property: lakeside, name: "Mortgage",        category: :mortgage,    amount_cents: 72_000,  billing_period: :monthly },
  { property: lakeside, name: "Home insurance",  category: :insurance,   amount_cents: 36_000,  billing_period: :yearly },
  { property: lakeside, name: "Life insurance",  category: :insurance,   amount_cents: 18_000,  billing_period: :yearly },
  { property: lakeside, name: "Property tax",    category: :tax,         amount_cents:  9_500,  billing_period: :yearly },
  { property: lakeside, name: "HOA fees",        category: :community,   amount_cents: 12_000,  billing_period: :monthly },
  { property: lakeside, name: "Contingency",     category: :contingency, amount_cents:  4_000,  billing_period: :monthly },

  { property: westend, name: "Mortgage",      category: :mortgage,    amount_cents: 90_000,  billing_period: :monthly },
  { property: westend, name: "Home insurance", category: :insurance,  amount_cents:  35_000,  billing_period: :monthly },
  { property: westend, name: "Property tax",   category: :tax,        amount_cents:  9_200,  billing_period: :monthly },
  { property: westend, name: "HOA fees",       category: :community,  amount_cents:  12_500,  billing_period: :monthly },
  { property: westend, name: "Contingency",    category: :contingency, amount_cents: 4_000,  billing_period: :monthly }
].each { |attrs| PropertyExpense.create!(attrs) }

# ── Income ────────────────────────────────────────────────────────────────────

[
  { name: "Salary",                  category: :income, amount_cents: 350_000, billing_period: :monthly },
  { name: "Rent — Downtown",         category: :income, amount_cents: 130_000, billing_period: :monthly, property: downtown },
  { name: "Rent — Lakeside Studio",  category: :income, amount_cents: 100_000, billing_period: :monthly, property: lakeside },
  { name: "Rent — West End",   category: :income, amount_cents:  160_000, billing_period: :monthly, property: westend }
].each { |attrs| LineItem.create!(attrs) }

# ── Housing ───────────────────────────────────────────────────────────────────

[
  { name: "Electricity",  category: :housing, amount_cents:  8_000, billing_period: :monthly },
  { name: "Water",        category: :housing, amount_cents:  3_500, billing_period: :monthly },
  { name: "Internet",     category: :housing, amount_cents:  4_500, billing_period: :monthly },
  { name: "Gas",          category: :housing, amount_cents:  2_500, billing_period: :monthly }
].each { |attrs| LineItem.create!(attrs) }

# ── Subscriptions ─────────────────────────────────────────────────────────────

[
  { name: "Streaming A",   category: :subscriptions, amount_cents: 1_599, billing_period: :monthly },
  { name: "Streaming B",   category: :subscriptions, amount_cents: 1_199, billing_period: :monthly },
  { name: "Cloud storage", category: :subscriptions, amount_cents: 2_999, billing_period: :yearly },
  { name: "Music",         category: :subscriptions, amount_cents:   999, billing_period: :monthly },
  { name: "News",          category: :subscriptions, amount_cents: 1_500, billing_period: :monthly }
].each { |attrs| LineItem.create!(attrs) }

# ── Investments ───────────────────────────────────────────────────────────────

[
  { name: "Index fund",    category: :investments, amount_cents: 50_000, billing_period: :monthly },
  { name: "Pension plan",  category: :investments, amount_cents: 20_000, billing_period: :monthly }
].each { |attrs| LineItem.create!(attrs) }

# ── Food & entertainment ──────────────────────────────────────────────────────

[
  { name: "Groceries",    category: :food_entertainment, amount_cents: 25_000, billing_period: :monthly },
  { name: "Dining out",   category: :food_entertainment, amount_cents: 15_000, billing_period: :monthly },
  { name: "Gym",          category: :food_entertainment, amount_cents:  4_500, billing_period: :monthly },
  { name: "Hobbies",      category: :food_entertainment, amount_cents:  8_000, billing_period: :monthly }
].each { |attrs| LineItem.create!(attrs) }

# ── Spending categories ───────────────────────────────────────────────────────

SpendingEntry.destroy_all
SpendingCategory.destroy_all

[
  { name: "Supermarket",    weekly_target_cents: 10_000, monthly_target_cents: 40_000 },
  { name: "Coffee & Cafes", weekly_target_cents:  2_500, monthly_target_cents: 10_000 },
  { name: "Dining Out",     weekly_target_cents:  5_000, monthly_target_cents: 20_000 },
  { name: "Transport",      weekly_target_cents:  3_000, monthly_target_cents: 12_000 },
  { name: "Misc",           weekly_target_cents:    nil, monthly_target_cents:    nil  }
].each { |attrs| SpendingCategory.create!(attrs) }

supermarket = SpendingCategory.find_by!(name: "Supermarket")
coffee      = SpendingCategory.find_by!(name: "Coffee & Cafes")
dining      = SpendingCategory.find_by!(name: "Dining Out")

[
  { spending_category: supermarket, amount_cents: 3_450, spent_on: Date.today,                   description: "Weekly shop" },
  { spending_category: supermarket, amount_cents: 1_200, spent_on: Date.today - 3,               description: "Top-up" },
  { spending_category: coffee,      amount_cents:   380, spent_on: Date.today,                   description: nil },
  { spending_category: coffee,      amount_cents:   420, spent_on: Date.today - 1,               description: nil },
  { spending_category: dining,      amount_cents: 4_800, spent_on: Date.today.beginning_of_week, description: "Dinner" }
].each { |attrs| SpendingEntry.create!(attrs) }
