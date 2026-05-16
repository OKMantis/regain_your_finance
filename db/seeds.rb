LineItem.destroy_all
PropertyExpense.destroy_all
Property.destroy_all

# ── Properties ────────────────────────────────────────────────────────────────

villanueva = Property.create!(name: "Villanueva de Castellón", ownership_percentage: 100)
frechina   = Property.create!(name: "Escultor de Frechina",   ownership_percentage: 100)
ruzafa     = Property.create!(name: "Cl Ruzafa",              ownership_percentage: 50)

# ── Property expenses ─────────────────────────────────────────────────────────

[
  { property: villanueva, name: "Mortgage",                category: :mortgage,    amount_cents: 28_700, billing_period: :monthly },
  { property: villanueva, name: "Home insurance",          category: :insurance,   amount_cents: 31_200, billing_period: :yearly },
  { property: villanueva, name: "Life insurance",          category: :insurance,   amount_cents: 20_100, billing_period: :yearly },
  { property: villanueva, name: "IBI",                     category: :tax,         amount_cents:  8_800, billing_period: :yearly },
  { property: villanueva, name: "Seguro de impago (SEAG)", category: :insurance,   amount_cents: 31_500, billing_period: :yearly },
  { property: villanueva, name: "Community",               category: :community,   amount_cents: 14_000, billing_period: :monthly },
  { property: villanueva, name: "Contingency fund",        category: :contingency, amount_cents:  5_000, billing_period: :monthly },

  { property: frechina, name: "Mortgage",                     category: :mortgage,    amount_cents: 33_800, billing_period: :monthly },
  { property: frechina, name: "Home insurance",               category: :insurance,   amount_cents: 38_000, billing_period: :yearly },
  { property: frechina, name: "Life insurance",               category: :insurance,   amount_cents: 18_600, billing_period: :yearly },
  { property: frechina, name: "IBI",                          category: :tax,         amount_cents: 14_800, billing_period: :yearly },
  { property: frechina, name: "Community (quarterly levy)",   category: :community,   amount_cents: 46_100, billing_period: :yearly },
  { property: frechina, name: "Community extra (renovation)", category: :community,   amount_cents:  5_000, billing_period: :monthly },
  { property: frechina, name: "Contingency fund",             category: :contingency, amount_cents:  5_000, billing_period: :monthly },

  # Ruzafa: Owen's 50% share only
  { property: ruzafa, name: "Home insurance (Owen 50%)",   category: :insurance,   amount_cents:  1_400, billing_period: :monthly },
  { property: ruzafa, name: "Life insurance (Owen 50%)",   category: :insurance,   amount_cents:  2_400, billing_period: :monthly },
  { property: ruzafa, name: "IBI (Owen 50%)",              category: :tax,         amount_cents:  1_700, billing_period: :monthly },
  { property: ruzafa, name: "Seguro de impago (Owen 50%)", category: :insurance,   amount_cents:  3_300, billing_period: :monthly },
  { property: ruzafa, name: "Community (Owen 50%)",        category: :community,   amount_cents: 12_000, billing_period: :monthly },
  { property: ruzafa, name: "Contingency fund (Owen 50%)", category: :contingency, amount_cents:  5_000, billing_period: :monthly }
].each { |attrs| PropertyExpense.create!(attrs) }

# ── Income ────────────────────────────────────────────────────────────────────

[
  { name: "Salary",                         category: :income, amount_cents: 100_000, billing_period: :monthly },
  { name: "Rent — Villanueva de Castellón", category: :income, amount_cents: 105_000, billing_period: :monthly, property: villanueva },
  { name: "Rent — Escultor de Frechina",    category: :income, amount_cents: 113_000, billing_period: :monthly, property: frechina },
  { name: "Rent — Cl Ruzafa (50%)",         category: :income, amount_cents:  77_000, billing_period: :monthly, property: ruzafa }
].each { |attrs| LineItem.create!(attrs) }

# ── Housing ───────────────────────────────────────────────────────────────────

[
  { name: "Rent C/ Enmig 33",       category: :housing, amount_cents: 100_000, billing_period: :monthly },
  { name: "Alarm & Internet house", category: :housing, amount_cents:   8_300, billing_period: :monthly }
].each { |attrs| LineItem.create!(attrs) }

# ── Subscriptions ─────────────────────────────────────────────────────────────

[
  { name: "Anthropic (Claude)",        category: :subscriptions, amount_cents:  2_200, billing_period: :monthly,   payment_method: "Debet card Wise" },
  { name: "iCloud",                    category: :subscriptions, amount_cents:    300, billing_period: :monthly,   payment_method: "Debet card Wise" },
  { name: "Amazon Prime",              category: :subscriptions, amount_cents:  5_000, billing_period: :yearly,    payment_method: "Debet card Wise" },
  { name: "1Password",                 category: :subscriptions, amount_cents:  4_100, billing_period: :yearly,    payment_method: "Debet card Wise" },
  { name: "Cleaning (mom, bi-weekly)", category: :subscriptions, amount_cents:  2_000, billing_period: :bi_weekly, payment_method: "Bank transfer to Justin" }
].each { |attrs| LineItem.create!(attrs) }

# ── Food & Entertainment ──────────────────────────────────────────────────────

LineItem.create!(
  name: "Food & Entertainment",
  category: :food_entertainment,
  amount_cents: 50_000,
  billing_period: :monthly
)

puts "Seeded:"
puts "  #{Property.count} properties"
puts "  #{PropertyExpense.count} property expenses"
puts "  #{LineItem.count} line items"

income_monthly  = LineItem.income.sum(:amount_cents_monthly)
expense_monthly = LineItem.where.not(category: :income).sum(:amount_cents_monthly) +
                  PropertyExpense.sum(:amount_cents_monthly)
savings_monthly = income_monthly - expense_monthly

puts "\nCalculated monthly savings: €#{"%.0f" % (savings_monthly / 100.0)}"
puts "Expected:                   €947"
