# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/dev                          # Start dev server (Rails + Tailwind watcher)
bin/rails test                   # Run full test suite
bin/rails test test/path/file.rb # Run a single test file
bin/rails test test/path/file.rb:42 # Run a single test by line number
bin/rubocop                      # Lint Ruby code
bin/brakeman                     # Security scan
bin/rails db:migrate             # Run migrations
bin/rails db:schema:load         # Load schema (faster than running all migrations)
```

## Architecture

**Regain** is a single-user personal finance dashboard with no authentication. Rails 8.1.3, Ruby 3.3.5, PostgreSQL, Tailwind CSS, Hotwire (Turbo + Stimulus), importmap, Propshaft.

### Data model

- **`LineItem`** — personal income and expenses (salary, subscriptions, food, etc.), optionally scoped to a property
- **`Property`** — a real estate property with an ownership percentage
- **`PropertyExpense`** — property-specific costs (mortgage, insurance, tax, community, contingency)

All monetary values are stored as integer cents in `amount_cents`. A `before_save` callback computes `amount_cents_monthly` by normalizing the billing period (monthly/yearly/quarterly/bi_weekly/weekly) using `MONTHLY_DIVISORS`. All display math should use `amount_cents_monthly` for aggregation, then convert to euros by dividing by 100.

`LineItem.category` enum: `income`, `housing`, `subscriptions`, `investments`, `food_entertainment`. Non-income items are expenses.

`PropertyExpense.category` enum: `mortgage`, `insurance`, `tax`, `community`, `contingency`.

### Pages & controllers

- **`/` (DashboardController#index)** — monthly/yearly savings summary, income list, expense breakdown by category
- **`/details` (DetailsController#index)** — line items grouped by category with inline editing
- **`/properties` (PropertiesController#index)** — per-property income, expenses, and net figures

Period toggle is a query param `?period=yearly`. Controllers set `@yearly = params[:period] == "yearly"` and views use a `multiplier` (1 or 12) to scale `amount_cents_monthly`.

### Frontend

Layout in `app/views/layouts/application.html.erb`: desktop sidebar (fixed, 256px, `lg:` breakpoint) + mobile bottom navigation bar. Main content offset with `lg:pl-64`.

Stimulus controllers in `app/javascript/controllers/`:
- `inline_edit_controller` — click-to-edit for line item amounts; converts euro input to cents before form submit
- `property_detail_controller` — property-level UI interactions

Tailwind CSS compiled via `bin/rails tailwindcss:watch` (run automatically by `bin/dev`). Source in `app/assets/tailwind/application.css`.

### Conventions

- Monetary display: always euros (divide cents by 100), use `number_with_delimiter(..., delimiter: ".")` for thousands separators, prefix with `€`
- Dark theme throughout: `bg-slate-950` body, `bg-slate-900` cards/sidebar, emerald accent (`emerald-400`/`emerald-500`) for positive values, red for expenses
- Page titles set via `content_for :page_title` in view templates
