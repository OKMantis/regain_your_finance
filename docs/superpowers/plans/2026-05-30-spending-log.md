# Spending Log Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Spending page where the user logs discretionary expenses (amount + flexible category) against weekly and monthly targets, with live Turbo Stream updates and an inline expand/edit card UI.

**Architecture:** Two new models (`SpendingCategory`, `SpendingEntry`) back a new `/spending` page. The page uses Turbo Streams to update individual card regions in-place (no full reload) and a new Stimulus controller (`spending_card_controller`) to manage the expand/edit toggle state on each category card.

**Tech Stack:** Rails 8.1, PostgreSQL, Turbo Streams, Stimulus, Tailwind CSS, Minitest (ActionDispatch::IntegrationTest for controller tests)

---

## File Map

**New — migrations**
- `db/migrate/<ts>_create_spending_categories.rb`
- `db/migrate/<ts>_create_spending_entries.rb`

**New — models**
- `app/models/spending_category.rb`
- `app/models/spending_entry.rb`

**New — controllers**
- `app/controllers/spending_controller.rb`
- `app/controllers/spending_categories_controller.rb`
- `app/controllers/spending_entries_controller.rb`

**New — views**
- `app/views/spending/index.html.erb`
- `app/views/spending/_quick_add_form.html.erb`
- `app/views/spending/_category_card.html.erb`
- `app/views/spending/_category_stats.html.erb`
- `app/views/spending/_category_entries.html.erb`
- `app/views/spending/_entry_row.html.erb`
- `app/views/spending/_new_category_form.html.erb`
- `app/views/spending_entries/create.turbo_stream.erb`
- `app/views/spending_entries/destroy.turbo_stream.erb`
- `app/views/spending_categories/create.turbo_stream.erb`
- `app/views/spending_categories/update.turbo_stream.erb`
- `app/views/spending_categories/destroy.turbo_stream.erb`

**New — JavaScript**
- `app/javascript/controllers/spending_card_controller.js`

**New — tests**
- `test/models/spending_category_test.rb`
- `test/models/spending_entry_test.rb`
- `test/controllers/spending_controller_test.rb`
- `test/controllers/spending_categories_controller_test.rb`
- `test/controllers/spending_entries_controller_test.rb`

**Modified**
- `config/routes.rb` — add spending routes
- `app/views/layouts/application.html.erb` — add Spending nav item to sidebar and mobile nav
- `app/helpers/application_helper.rb` — add two progress bar helpers

---

## Task 1: Migrations

**Files:**
- Create: `db/migrate/<ts>_create_spending_categories.rb`
- Create: `db/migrate/<ts>_create_spending_entries.rb`

- [ ] **Step 1: Generate the migrations**

```bash
bin/rails generate migration CreateSpendingCategories name:string weekly_target_cents:integer monthly_target_cents:integer
bin/rails generate migration CreateSpendingEntries spending_category:references amount_cents:integer description:string spent_on:date
```

- [ ] **Step 2: Edit the spending_categories migration to add the uniqueness index**

Open the generated file at `db/migrate/<ts>_create_spending_categories.rb` and replace it with:

```ruby
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
```

- [ ] **Step 3: Edit the spending_entries migration to add constraints and indexes**

Open the generated file at `db/migrate/<ts>_create_spending_entries.rb` and replace it with:

```ruby
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
```

- [ ] **Step 4: Run the migrations**

```bash
bin/rails db:migrate
```

Expected output: two `CreateSpendingCategories` and `CreateSpendingEntries` lines with `migrated`.

- [ ] **Step 5: Commit**

```bash
git add db/migrate db/schema.rb
git commit -m "Add spending_categories and spending_entries migrations"
```

---

## Task 2: SpendingCategory Model

**Files:**
- Create: `app/models/spending_category.rb`
- Create: `test/models/spending_category_test.rb`

- [ ] **Step 1: Write the failing model test**

Create `test/models/spending_category_test.rb`:

```ruby
require "test_helper"

class SpendingCategoryTest < ActiveSupport::TestCase
  def valid_category
    SpendingCategory.new(name: "Groceries")
  end

  test "valid with name only" do
    assert valid_category.valid?
  end

  test "invalid without name" do
    cat = valid_category
    cat.name = nil
    assert_not cat.valid?
    assert_includes cat.errors[:name], "can't be blank"
  end

  test "invalid with duplicate name" do
    SpendingCategory.create!(name: "Coffee")
    dup = SpendingCategory.new(name: "Coffee")
    assert_not dup.valid?
    assert_includes dup.errors[:name], "has already been taken"
  end

  test "weekly_target_cents must be non-negative if present" do
    cat = valid_category
    cat.weekly_target_cents = -1
    assert_not cat.valid?
  end

  test "weekly_target_cents can be nil" do
    cat = valid_category
    cat.weekly_target_cents = nil
    assert cat.valid?
  end

  test "monthly_target_cents must be non-negative if present" do
    cat = valid_category
    cat.monthly_target_cents = -1
    assert_not cat.valid?
  end

  test "has many spending_entries destroyed on delete" do
    cat = SpendingCategory.create!(name: "Groceries")
    cat.spending_entries.create!(amount_cents: 1000, spent_on: Date.today)
    assert_difference "SpendingEntry.count", -1 do
      cat.destroy
    end
  end

  test "weeks_in_month returns correct week buckets" do
    cat = SpendingCategory.create!(name: "Test", weekly_target_cents: 5000)
    # Create entries on May 5 (week 1) and May 12 (week 2)
    cat.spending_entries.create!(amount_cents: 2000, spent_on: Date.new(2026, 5, 5))
    cat.spending_entries.create!(amount_cents: 3000, spent_on: Date.new(2026, 5, 12))

    weeks = cat.weeks_in_month(Date.new(2026, 5, 1))
    assert weeks.length >= 4
    total_spent = weeks.sum { |w| w[:spent_cents] }
    assert_equal 5000, total_spent
  end
end
```

- [ ] **Step 2: Run the test — expect failure**

```bash
bin/rails test test/models/spending_category_test.rb
```

Expected: errors like `uninitialized constant SpendingCategory`.

- [ ] **Step 3: Write the model**

Create `app/models/spending_category.rb`:

```ruby
class SpendingCategory < ApplicationRecord
  has_many :spending_entries, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :weekly_target_cents,  numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :monthly_target_cents, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  # Returns an array of week buckets for the given month.
  # Each bucket: { start: Date, end: Date, spent_cents: Integer, target_cents: Integer|nil }
  # Week boundary: Monday (Rails default / ISO week).
  def weeks_in_month(date = Date.today)
    month_start = date.beginning_of_month
    month_end   = date.end_of_month
    buckets     = []
    cursor      = month_start.beginning_of_week

    while cursor <= month_end
      wk_start = [cursor, month_start].max
      wk_end   = [cursor.end_of_week, month_end].min
      spent    = spending_entries.where(spent_on: wk_start..wk_end).sum(:amount_cents)
      buckets << { start: wk_start, end: wk_end, spent_cents: spent, target_cents: weekly_target_cents }
      cursor += 7
    end

    buckets
  end
end
```

- [ ] **Step 4: Run the test — expect pass**

```bash
bin/rails test test/models/spending_category_test.rb
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/models/spending_category.rb test/models/spending_category_test.rb
git commit -m "Add SpendingCategory model with validations and weeks_in_month"
```

---

## Task 3: SpendingEntry Model

**Files:**
- Create: `app/models/spending_entry.rb`
- Create: `test/models/spending_entry_test.rb`

- [ ] **Step 1: Write the failing model test**

Create `test/models/spending_entry_test.rb`:

```ruby
require "test_helper"

class SpendingEntryTest < ActiveSupport::TestCase
  def category
    @category ||= SpendingCategory.create!(name: "Groceries")
  end

  def valid_entry
    SpendingEntry.new(spending_category: category, amount_cents: 1500, spent_on: Date.today)
  end

  test "valid with required fields" do
    assert valid_entry.valid?
  end

  test "invalid without amount_cents" do
    e = valid_entry
    e.amount_cents = nil
    assert_not e.valid?
  end

  test "invalid with negative amount_cents" do
    e = valid_entry
    e.amount_cents = -1
    assert_not e.valid?
  end

  test "invalid without spent_on" do
    e = valid_entry
    e.spent_on = nil
    assert_not e.valid?
  end

  test "invalid without spending_category" do
    e = valid_entry
    e.spending_category = nil
    assert_not e.valid?
  end

  test "description is optional" do
    e = valid_entry
    e.description = nil
    assert e.valid?
  end

  test "amount_euros returns decimal euros" do
    e = valid_entry
    e.amount_cents = 1550
    assert_equal 15.5, e.amount_euros
  end
end
```

- [ ] **Step 2: Run the test — expect failure**

```bash
bin/rails test test/models/spending_entry_test.rb
```

Expected: `uninitialized constant SpendingEntry`.

- [ ] **Step 3: Write the model**

Create `app/models/spending_entry.rb`:

```ruby
class SpendingEntry < ApplicationRecord
  belongs_to :spending_category

  validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :spent_on,     presence: true

  def amount_euros
    amount_cents / 100.0
  end
end
```

- [ ] **Step 4: Run the test — expect pass**

```bash
bin/rails test test/models/spending_entry_test.rb
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/models/spending_entry.rb test/models/spending_entry_test.rb
git commit -m "Add SpendingEntry model with validations"
```

---

## Task 4: Routes

**Files:**
- Modify: `config/routes.rb`

- [ ] **Step 1: Add spending routes**

Open `config/routes.rb` and add after the `resources :property_expenses` line:

```ruby
get  "spending", to: "spending#index", as: :spending
resources :spending_categories, only: [ :create, :update, :destroy ]
resources :spending_entries,    only: [ :create, :destroy ]
```

- [ ] **Step 2: Verify routes exist**

```bash
bin/rails routes | grep spending
```

Expected output includes:
```
spending  GET   /spending(.:format)                       spending#index
          POST  /spending_categories(.:format)            spending_categories#create
          PATCH /spending_categories/:id(.:format)        spending_categories#update
          PUT   /spending_categories/:id(.:format)        spending_categories#update
          DELETE /spending_categories/:id(.:format)       spending_categories#destroy
          POST  /spending_entries(.:format)               spending_entries#create
          DELETE /spending_entries/:id(.:format)          spending_entries#destroy
```

- [ ] **Step 3: Commit**

```bash
git add config/routes.rb
git commit -m "Add spending routes"
```

---

## Task 5: SpendingController

**Files:**
- Create: `app/controllers/spending_controller.rb`
- Create: `test/controllers/spending_controller_test.rb`

- [ ] **Step 1: Write the failing controller test**

Create `test/controllers/spending_controller_test.rb`:

```ruby
require "test_helper"

class SpendingControllerTest < ActionDispatch::IntegrationTest
  test "GET /spending renders successfully with no categories" do
    get spending_path
    assert_response :success
  end

  test "GET /spending renders categories with weekly and monthly totals" do
    cat = SpendingCategory.create!(name: "Coffee", weekly_target_cents: 2000, monthly_target_cents: 8000)
    SpendingEntry.create!(spending_category: cat, amount_cents: 500, spent_on: Date.today)

    get spending_path
    assert_response :success
    assert_select "div#spending_categories_list"
    assert_select "div#spending_category_stats_#{cat.id}"
  end

  test "GET /spending with period=yearly responds successfully" do
    get spending_path, params: { period: "yearly" }
    assert_response :success
  end
end
```

- [ ] **Step 2: Run the test — expect failure**

```bash
bin/rails test test/controllers/spending_controller_test.rb
```

Expected: routing error or missing template.

- [ ] **Step 3: Write the controller**

Create `app/controllers/spending_controller.rb`:

```ruby
class SpendingController < ApplicationController
  def index
    @yearly     = params[:period] == "yearly"
    @categories = SpendingCategory.order(:name)

    today       = Date.today
    week_range  = today.beginning_of_week..today.end_of_week
    month_range = today.beginning_of_month..today.end_of_month

    @weekly_totals  = SpendingEntry.where(spent_on: week_range)
                                   .group(:spending_category_id)
                                   .sum(:amount_cents)
    @monthly_totals = SpendingEntry.where(spent_on: month_range)
                                   .group(:spending_category_id)
                                   .sum(:amount_cents)

    if @yearly
      year_range     = today.beginning_of_year..today.end_of_year
      @yearly_totals = SpendingEntry.where(spent_on: year_range)
                                    .group(:spending_category_id)
                                    .sum(:amount_cents)
    end

    @entries_by_category = SpendingEntry.where(spent_on: month_range)
                                        .order(spent_on: :desc)
                                        .group_by(&:spending_category_id)
  end
end
```

- [ ] **Step 4: Create a minimal index view so the test can find a template**

Create `app/views/spending/index.html.erb` with just enough to pass the test:

```erb
<% content_for :page_title, "Spending" %>

<div id="spending_categories_list">
  <% @categories.each do |category| %>
    <div id="spending_category_<%= category.id %>">
      <div id="spending_category_stats_<%= category.id %>"></div>
    </div>
  <% end %>
</div>
```

- [ ] **Step 5: Run the test — expect pass**

```bash
bin/rails test test/controllers/spending_controller_test.rb
```

Expected: all 3 tests pass.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/spending_controller.rb app/views/spending/index.html.erb test/controllers/spending_controller_test.rb
git commit -m "Add SpendingController with N+1-free index action"
```

---

## Task 6: ApplicationHelper Progress Bar Helpers

**Files:**
- Modify: `app/helpers/application_helper.rb`

- [ ] **Step 1: Add helpers to application_helper.rb**

Open `app/helpers/application_helper.rb` and add these two methods inside the `ApplicationHelper` module:

```ruby
# Returns the Tailwind colour class for a progress bar given spent vs target.
# Returns nil when no target is set (no colour rendered).
def progress_bar_color(spent_cents, target_cents)
  return nil if target_cents.nil? || target_cents.zero?
  pct = spent_cents * 100.0 / target_cents
  if pct < 80
    "bg-emerald-500"
  elsif pct < 100
    "bg-amber-500"
  else
    "bg-red-500"
  end
end

# Returns the CSS width percentage string for a progress bar, capped at 100%.
# Returns "0%" when no target is set.
def progress_bar_width(spent_cents, target_cents)
  return "0%" if target_cents.nil? || target_cents.zero?
  pct = [spent_cents * 100.0 / target_cents, 100].min
  "#{pct.round(1)}%"
end
```

- [ ] **Step 2: Commit**

```bash
git add app/helpers/application_helper.rb
git commit -m "Add progress_bar_color and progress_bar_width helpers"
```

---

## Task 7: Spending Views — All Partials

**Files:**
- Modify: `app/views/spending/index.html.erb` (replace stub from Task 5)
- Create: `app/views/spending/_quick_add_form.html.erb`
- Create: `app/views/spending/_category_card.html.erb`
- Create: `app/views/spending/_category_stats.html.erb`
- Create: `app/views/spending/_category_entries.html.erb`
- Create: `app/views/spending/_entry_row.html.erb`
- Create: `app/views/spending/_new_category_form.html.erb`

- [ ] **Step 1: Write the entry row partial**

Create `app/views/spending/_entry_row.html.erb`:

```erb
<div id="spending_entry_<%= entry.id %>" class="flex items-center justify-between py-2 border-b border-slate-800/40 last:border-0">
  <div class="flex items-center gap-3 min-w-0">
    <span class="text-slate-500 text-xs w-16 flex-shrink-0"><%= entry.spent_on.strftime("%b %d") %></span>
    <span class="text-slate-300 text-sm truncate"><%= entry.description.presence || "—" %></span>
  </div>
  <div class="flex items-center gap-2 flex-shrink-0 ml-2">
    <span class="text-white text-sm font-medium"><%= format_euros(entry.amount_cents) %></span>
    <%= button_to spending_entry_path(entry),
          method: :delete,
          params: { period: yearly ? "yearly" : nil },
          data: { turbo_confirm: "Delete this entry?" },
          class: "text-slate-600 hover:text-red-400 transition-colors p-1" do %>
      <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
      </svg>
    <% end %>
  </div>
</div>
```

- [ ] **Step 2: Write the category stats partial**

Create `app/views/spending/_category_stats.html.erb`:

```erb
<div id="spending_category_stats_<%= category.id %>">
  <% if yearly %>
    <%# Year-to-date mode: show YTD vs 12× monthly target %>
    <% ytd = yearly_total || 0 %>
    <% ytd_target = category.monthly_target_cents ? category.monthly_target_cents * 12 : nil %>
    <div class="mt-3 space-y-1.5">
      <div class="flex justify-between text-xs">
        <span class="text-slate-400">Year to date</span>
        <span class="text-white font-medium">
          <%= format_euros(ytd) %>
          <% if ytd_target %><span class="text-slate-500"> / <%= format_euros(ytd_target) %></span><% end %>
        </span>
      </div>
      <% if ytd_target %>
        <div class="h-1.5 bg-slate-800 rounded-full overflow-hidden">
          <div class="h-full rounded-full transition-all <%= progress_bar_color(ytd, ytd_target) || 'bg-slate-600' %>"
               style="width: <%= progress_bar_width(ytd, ytd_target) %>"></div>
        </div>
      <% end %>
    </div>
  <% else %>
    <%# Monthly / weekly mode %>
    <% w_spent = weekly_total || 0 %>
    <% m_spent = monthly_total || 0 %>
    <div class="mt-3 space-y-2">
      <%# Weekly bar %>
      <div>
        <div class="flex justify-between text-xs mb-1">
          <span class="text-slate-400">This week</span>
          <span class="text-white font-medium">
            <%= format_euros(w_spent) %>
            <% if category.weekly_target_cents %><span class="text-slate-500"> / <%= format_euros(category.weekly_target_cents) %></span><% end %>
          </span>
        </div>
        <% if category.weekly_target_cents %>
          <div class="h-1.5 bg-slate-800 rounded-full overflow-hidden">
            <div class="h-full rounded-full transition-all <%= progress_bar_color(w_spent, category.weekly_target_cents) %>"
                 style="width: <%= progress_bar_width(w_spent, category.weekly_target_cents) %>"></div>
          </div>
        <% end %>
      </div>
      <%# Monthly bar %>
      <div>
        <div class="flex justify-between text-xs mb-1">
          <span class="text-slate-400">This month</span>
          <span class="text-white font-medium">
            <%= format_euros(m_spent) %>
            <% if category.monthly_target_cents %><span class="text-slate-500"> / <%= format_euros(category.monthly_target_cents) %></span><% end %>
          </span>
        </div>
        <% if category.monthly_target_cents %>
          <div class="h-1.5 bg-slate-800 rounded-full overflow-hidden">
            <div class="h-full rounded-full transition-all <%= progress_bar_color(m_spent, category.monthly_target_cents) %>"
                 style="width: <%= progress_bar_width(m_spent, category.monthly_target_cents) %>"></div>
          </div>
        <% end %>
      </div>
    </div>
  <% end %>
</div>
```

- [ ] **Step 3: Write the category entries partial**

Create `app/views/spending/_category_entries.html.erb`:

```erb
<div id="spending_category_entries_<%= category.id %>"
     data-spending-card-target="entries"
     class="hidden mt-4 border-t border-slate-800/60 pt-4">

  <%# Entry list for current month %>
  <div class="mb-4">
    <p class="text-xs text-slate-500 font-medium uppercase tracking-wide mb-2">Entries this month</p>
    <% if entries.empty? %>
      <p class="text-slate-600 text-sm">No entries this month.</p>
    <% else %>
      <% entries.each do |entry| %>
        <%= render "spending/entry_row", entry: entry, yearly: yearly %>
      <% end %>
    <% end %>
  </div>

  <%# Week-by-week breakdown %>
  <div>
    <p class="text-xs text-slate-500 font-medium uppercase tracking-wide mb-2">Week breakdown</p>
    <table class="w-full text-xs">
      <thead>
        <tr class="text-slate-500">
          <th class="text-left pb-1 font-normal">Week</th>
          <th class="text-right pb-1 font-normal">Spent</th>
          <% if category.weekly_target_cents %>
            <th class="text-right pb-1 font-normal">Target</th>
            <th class="text-right pb-1 font-normal">Diff</th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <% category.weeks_in_month.each do |wk| %>
          <tr class="border-t border-slate-800/30">
            <td class="py-1 text-slate-400">
              <%= wk[:start].strftime("%b %d") %> – <%= wk[:end].strftime("%b %d") %>
            </td>
            <td class="py-1 text-right text-white"><%= format_euros(wk[:spent_cents]) %></td>
            <% if category.weekly_target_cents %>
              <td class="py-1 text-right text-slate-400"><%= format_euros(wk[:target_cents]) %></td>
              <% diff = wk[:target_cents] - wk[:spent_cents] %>
              <td class="py-1 text-right <%= diff >= 0 ? 'text-emerald-400' : 'text-red-400' %>">
                <%= diff >= 0 ? "+" : "" %><%= format_euros(diff.abs) %><%= diff < 0 ? " over" : "" %>
              </td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
```

- [ ] **Step 4: Write the full category card partial**

Create `app/views/spending/_category_card.html.erb`:

```erb
<div id="spending_category_<%= category.id %>"
     class="bg-slate-900 rounded-xl border border-slate-800/60 px-5 py-4"
     data-controller="spending-card">

  <%# ── Header (visible by default) ── %>
  <div data-spending-card-target="header" class="flex items-center justify-between">
    <button data-action="spending-card#toggleEntries"
            class="flex-1 text-left">
      <span class="text-white font-medium"><%= category.name %></span>
    </button>
    <div class="flex items-center gap-1 ml-2">
      <%# Edit button %>
      <button data-action="spending-card#startEdit"
              class="text-slate-500 hover:text-slate-300 transition-colors p-1.5 rounded-lg hover:bg-slate-800">
        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
        </svg>
      </button>
      <%# Delete button %>
      <%= button_to spending_category_path(category),
            method: :delete,
            data: { turbo_confirm: "Delete \"#{category.name}\" and all its entries?" },
            class: "text-slate-500 hover:text-red-400 transition-colors p-1.5 rounded-lg hover:bg-slate-800" do %>
        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
        </svg>
      <% end %>
      <%# Expand chevron %>
      <button data-action="spending-card#toggleEntries"
              class="text-slate-500 hover:text-slate-300 transition-colors p-1.5">
        <svg data-spending-card-target="chevron"
             class="w-4 h-4 transition-transform duration-150"
             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"/>
        </svg>
      </button>
    </div>
  </div>

  <%# ── Inline edit form (hidden by default) ── %>
  <div data-spending-card-target="editForm" class="hidden">
    <%= form_with url: spending_category_path(category), method: :patch, data: { turbo: true } do |f| %>
      <div class="flex items-center gap-2 mb-3">
        <%= f.text_field :name, value: category.name,
              class: "flex-1 bg-slate-800 border border-slate-700 rounded-lg px-3 py-1.5 text-white text-sm focus:outline-none focus:border-emerald-500",
              placeholder: "Category name", required: true %>
        <button type="submit" class="text-emerald-400 hover:text-emerald-300 text-sm font-medium px-2">Save</button>
        <button type="button" data-action="spending-card#cancelEdit"
                class="text-slate-500 hover:text-slate-300 text-sm px-2">Cancel</button>
      </div>
      <div class="flex gap-2">
        <%= f.number_field :weekly_target_euros,
              value: category.weekly_target_cents ? (category.weekly_target_cents / 100.0).round : nil,
              step: 0.01, min: 0,
              class: "w-1/2 bg-slate-800 border border-slate-700 rounded-lg px-3 py-1.5 text-white text-sm focus:outline-none focus:border-emerald-500",
              placeholder: "Weekly target (€)" %>
        <%= f.number_field :monthly_target_euros,
              value: category.monthly_target_cents ? (category.monthly_target_cents / 100.0).round : nil,
              step: 0.01, min: 0,
              class: "w-1/2 bg-slate-800 border border-slate-700 rounded-lg px-3 py-1.5 text-white text-sm focus:outline-none focus:border-emerald-500",
              placeholder: "Monthly target (€)" %>
      </div>
      <%= f.hidden_field :period, value: yearly ? "yearly" : nil %>
    <% end %>
  </div>

  <%# ── Stats (always visible) ── %>
  <%= render "spending/category_stats",
        category: category,
        weekly_total: weekly_total,
        monthly_total: monthly_total,
        yearly_total: yearly_total,
        yearly: yearly %>

  <%# ── Entries (hidden, toggled by Stimulus) ── %>
  <%= render "spending/category_entries",
        category: category,
        entries: entries,
        yearly: yearly %>
</div>
```

- [ ] **Step 5: Write the quick-add form partial**

Create `app/views/spending/_quick_add_form.html.erb`:

```erb
<div id="quick_add_form" class="bg-slate-900 rounded-xl border border-slate-800/60 px-5 py-4">
  <p class="text-xs text-slate-500 font-medium uppercase tracking-wide mb-3">Log expense</p>
  <%= form_with url: spending_entries_path, method: :post, data: { turbo: true },
        class: "flex flex-col sm:flex-row gap-2" do |f| %>
    <%= f.select :spending_category_id,
          categories.map { |c| [c.name, c.id] },
          {},
          class: "bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-emerald-500 sm:w-40" %>
    <div class="relative flex-1">
      <span class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-sm">€</span>
      <%= f.number_field :amount_euros, step: 0.01, min: 0,
            class: "w-full bg-slate-800 border border-slate-700 rounded-lg pl-7 pr-3 py-2 text-white text-sm focus:outline-none focus:border-emerald-500",
            placeholder: "0.00", required: true,
            id: "quick_add_amount" %>
    </div>
    <%= f.text_field :description,
          class: "flex-1 bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-emerald-500",
          placeholder: "Description (optional)" %>
    <%= f.hidden_field :period, value: yearly ? "yearly" : nil %>
    <%= f.submit "Add",
          class: "bg-emerald-600 hover:bg-emerald-500 text-white text-sm font-medium px-4 py-2 rounded-lg transition-colors cursor-pointer" %>
  <% end %>
</div>
```

- [ ] **Step 6: Write the new category form partial**

Create `app/views/spending/_new_category_form.html.erb`:

```erb
<div id="new_category_form">
  <details class="group">
    <summary class="cursor-pointer text-sm text-slate-500 hover:text-slate-300 transition-colors list-none flex items-center gap-1.5">
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
      </svg>
      New category
    </summary>
    <div class="mt-3 bg-slate-900 rounded-xl border border-slate-800/60 px-5 py-4">
      <%= form_with url: spending_categories_path, method: :post, data: { turbo: true } do |f| %>
        <div class="space-y-2">
          <%= f.text_field :name,
                class: "w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-emerald-500",
                placeholder: "Category name (e.g. Groceries)", required: true %>
          <div class="flex gap-2">
            <%= f.number_field :weekly_target_euros, step: 0.01, min: 0,
                  class: "w-1/2 bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-emerald-500",
                  placeholder: "Weekly target (€)" %>
            <%= f.number_field :monthly_target_euros, step: 0.01, min: 0,
                  class: "w-1/2 bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-emerald-500",
                  placeholder: "Monthly target (€)" %>
          </div>
          <%= f.hidden_field :period, value: nil %>
          <%= f.submit "Create category",
                class: "w-full bg-emerald-600 hover:bg-emerald-500 text-white text-sm font-medium py-2 rounded-lg transition-colors cursor-pointer" %>
        </div>
      <% end %>
    </div>
  </details>
</div>
```

- [ ] **Step 7: Replace the stub index view with the full version**

Replace `app/views/spending/index.html.erb` with:

```erb
<% content_for :page_title, "Spending" %>

<div class="space-y-4 pt-4 lg:pt-0">

  <%# ── Quick-add form ── %>
  <% if @categories.any? %>
    <%= render "spending/quick_add_form", categories: @categories, yearly: @yearly %>
  <% end %>

  <%# ── Category cards ── %>
  <% if @categories.empty? %>
    <div class="flex flex-col items-center justify-center py-16 text-center">
      <div class="w-12 h-12 rounded-xl bg-slate-900 border border-slate-800/60 flex items-center justify-center mb-4">
        <svg class="w-6 h-6 text-slate-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 00-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75"/>
        </svg>
      </div>
      <p class="text-slate-400 text-sm font-medium">Add your first spending category to start tracking</p>
      <p class="text-slate-600 text-xs mt-1">Use the form below to create categories like Groceries, Coffee, Dining Out</p>
    </div>
  <% else %>
    <div id="spending_categories_list" class="space-y-3">
      <% @categories.each do |category| %>
        <%= render "spending/category_card",
              category: category,
              weekly_total:  @weekly_totals[category.id]  || 0,
              monthly_total: @monthly_totals[category.id] || 0,
              yearly_total:  @yearly ? (@yearly_totals[category.id] || 0) : nil,
              entries:       @entries_by_category[category.id] || [],
              yearly:        @yearly %>
      <% end %>
    </div>
  <% end %>

  <%# ── New category ── %>
  <%= render "spending/new_category_form" %>

</div>
```

- [ ] **Step 8: Run the controller test again — expect pass**

```bash
bin/rails test test/controllers/spending_controller_test.rb
```

Expected: all 3 tests pass.

- [ ] **Step 9: Commit**

```bash
git add app/views/spending/ app/helpers/application_helper.rb
git commit -m "Add all spending views and partials"
```

---

## Task 8: SpendingCategoriesController + Turbo Stream Templates

**Files:**
- Create: `app/controllers/spending_categories_controller.rb`
- Create: `app/views/spending_categories/create.turbo_stream.erb`
- Create: `app/views/spending_categories/update.turbo_stream.erb`
- Create: `app/views/spending_categories/destroy.turbo_stream.erb`
- Create: `test/controllers/spending_categories_controller_test.rb`

- [ ] **Step 1: Write failing tests**

Create `test/controllers/spending_categories_controller_test.rb`:

```ruby
require "test_helper"

class SpendingCategoriesControllerTest < ActionDispatch::IntegrationTest
  test "POST /spending_categories creates a category and redirects (html)" do
    assert_difference "SpendingCategory.count", 1 do
      post spending_categories_path,
           params: { spending_category: { name: "Coffee", weekly_target_euros: "20", monthly_target_euros: "80" } }
    end
    assert_redirected_to spending_path
    cat = SpendingCategory.last
    assert_equal "Coffee", cat.name
    assert_equal 2000, cat.weekly_target_cents
    assert_equal 8000, cat.monthly_target_cents
  end

  test "POST /spending_categories with turbo_stream responds with stream" do
    post spending_categories_path,
         params: { spending_category: { name: "Groceries" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "PATCH /spending_categories/:id updates the category" do
    cat = SpendingCategory.create!(name: "Drinks")
    patch spending_category_path(cat),
          params: { spending_category: { name: "Coffee & Tea", weekly_target_euros: "15" } }
    assert_redirected_to spending_path
    assert_equal "Coffee & Tea", cat.reload.name
    assert_equal 1500, cat.reload.weekly_target_cents
  end

  test "DELETE /spending_categories/:id destroys category and entries" do
    cat = SpendingCategory.create!(name: "Misc")
    cat.spending_entries.create!(amount_cents: 500, spent_on: Date.today)
    assert_difference ["SpendingCategory.count", "SpendingEntry.count"], -1 do
      delete spending_category_path(cat)
    end
    assert_redirected_to spending_path
  end

  test "POST with invalid name does not create category" do
    assert_no_difference "SpendingCategory.count" do
      post spending_categories_path,
           params: { spending_category: { name: "" } }
    end
    assert_redirected_to spending_path
  end
end
```

- [ ] **Step 2: Run tests — expect failure**

```bash
bin/rails test test/controllers/spending_categories_controller_test.rb
```

Expected: routing or missing controller error.

- [ ] **Step 3: Write the controller**

Create `app/controllers/spending_categories_controller.rb`:

```ruby
class SpendingCategoriesController < ApplicationController
  before_action :set_category, only: [ :update, :destroy ]

  def create
    @category = SpendingCategory.new(category_params)

    if @category.save
      @yearly = params[:spending_category][:period] == "yearly"
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to spending_path }
      end
    else
      respond_to do |format|
        format.turbo_stream { redirect_to spending_path }
        format.html { redirect_to spending_path }
      end
    end
  end

  def update
    @yearly = params[:spending_category][:period] == "yearly"

    if @category.update(category_params)
      today = Date.today
      week_range  = today.beginning_of_week..today.end_of_week
      month_range = today.beginning_of_month..today.end_of_month

      @weekly_total  = @category.spending_entries.where(spent_on: week_range).sum(:amount_cents)
      @monthly_total = @category.spending_entries.where(spent_on: month_range).sum(:amount_cents)
      @yearly_total  = @yearly ? @category.spending_entries.where(spent_on: today.beginning_of_year..today.end_of_year).sum(:amount_cents) : nil
      @entries       = @category.spending_entries.where(spent_on: month_range).order(spent_on: :desc)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to spending_path }
      end
    else
      respond_to do |format|
        format.turbo_stream { redirect_to spending_path }
        format.html { redirect_to spending_path }
      end
    end
  end

  def destroy
    @category.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to spending_path }
    end
  end

  private

  def set_category
    @category = SpendingCategory.find(params[:id])
  end

  def category_params
    raw = params.require(:spending_category).permit(:name, :weekly_target_euros, :monthly_target_euros, :period)
    attrs = { name: raw[:name] }
    attrs[:weekly_target_cents]  = euros_to_cents(raw[:weekly_target_euros])
    attrs[:monthly_target_cents] = euros_to_cents(raw[:monthly_target_euros])
    attrs
  end

  def euros_to_cents(value)
    return nil if value.blank?
    (value.to_f * 100).round
  end
end
```

- [ ] **Step 4: Create Turbo Stream templates**

Create `app/views/spending_categories/create.turbo_stream.erb`:

```erb
<%= turbo_stream.append "spending_categories_list" do %>
  <%= render "spending/category_card",
        category: @category,
        weekly_total: 0,
        monthly_total: 0,
        yearly_total: nil,
        entries: [],
        yearly: @yearly %>
<% end %>
<%= turbo_stream.replace "new_category_form" do %>
  <%= render "spending/new_category_form" %>
<% end %>
```

Create `app/views/spending_categories/update.turbo_stream.erb`:

```erb
<%= turbo_stream.replace "spending_category_#{@category.id}" do %>
  <%= render "spending/category_card",
        category: @category,
        weekly_total: @weekly_total,
        monthly_total: @monthly_total,
        yearly_total: @yearly_total,
        entries: @entries,
        yearly: @yearly %>
<% end %>
```

Create `app/views/spending_categories/destroy.turbo_stream.erb`:

```erb
<%= turbo_stream.remove "spending_category_#{@category.id}" %>
```

- [ ] **Step 5: Run tests — expect pass**

```bash
bin/rails test test/controllers/spending_categories_controller_test.rb
```

Expected: all 5 tests pass.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/spending_categories_controller.rb app/views/spending_categories/ test/controllers/spending_categories_controller_test.rb
git commit -m "Add SpendingCategoriesController with Turbo Stream templates"
```

---

## Task 9: SpendingEntriesController + Turbo Stream Templates

**Files:**
- Create: `app/controllers/spending_entries_controller.rb`
- Create: `app/views/spending_entries/create.turbo_stream.erb`
- Create: `app/views/spending_entries/destroy.turbo_stream.erb`
- Create: `test/controllers/spending_entries_controller_test.rb`

- [ ] **Step 1: Write failing tests**

Create `test/controllers/spending_entries_controller_test.rb`:

```ruby
require "test_helper"

class SpendingEntriesControllerTest < ActionDispatch::IntegrationTest
  def category
    @category ||= SpendingCategory.create!(name: "Groceries", weekly_target_cents: 5000, monthly_target_cents: 20000)
  end

  test "POST /spending_entries creates entry with today's date" do
    assert_difference "SpendingEntry.count", 1 do
      post spending_entries_path,
           params: { spending_entry: { spending_category_id: category.id, amount_euros: "12.50", description: "Carrots" } }
    end
    assert_redirected_to spending_path
    entry = SpendingEntry.last
    assert_equal 1250, entry.amount_cents
    assert_equal Date.today, entry.spent_on
    assert_equal "Carrots", entry.description
  end

  test "POST /spending_entries with turbo_stream responds with stream" do
    post spending_entries_path,
         params: { spending_entry: { spending_category_id: category.id, amount_euros: "5.00" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "POST /spending_entries with blank amount does not create entry" do
    assert_no_difference "SpendingEntry.count" do
      post spending_entries_path,
           params: { spending_entry: { spending_category_id: category.id, amount_euros: "" } }
    end
    assert_redirected_to spending_path
  end

  test "DELETE /spending_entries/:id destroys the entry" do
    entry = SpendingEntry.create!(spending_category: category, amount_cents: 800, spent_on: Date.today)
    assert_difference "SpendingEntry.count", -1 do
      delete spending_entry_path(entry)
    end
    assert_redirected_to spending_path
  end

  test "DELETE /spending_entries/:id with turbo_stream responds with stream" do
    entry = SpendingEntry.create!(spending_category: category, amount_cents: 800, spent_on: Date.today)
    delete spending_entry_path(entry),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end
end
```

- [ ] **Step 2: Run tests — expect failure**

```bash
bin/rails test test/controllers/spending_entries_controller_test.rb
```

Expected: routing or missing controller error.

- [ ] **Step 3: Write the controller**

Create `app/controllers/spending_entries_controller.rb`:

```ruby
class SpendingEntriesController < ApplicationController
  def create
    @entry = SpendingEntry.new(entry_params)
    @entry.spent_on = Date.today

    if @entry.save
      @category = @entry.spending_category
      @yearly   = params[:spending_entry][:period] == "yearly"
      compute_category_totals
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to spending_path }
      end
    else
      respond_to do |format|
        format.turbo_stream { redirect_to spending_path }
        format.html { redirect_to spending_path }
      end
    end
  end

  def destroy
    @entry    = SpendingEntry.find(params[:id])
    @category = @entry.spending_category
    @yearly   = params[:period] == "yearly"
    @entry.destroy
    compute_category_totals
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to spending_path }
    end
  end

  private

  def entry_params
    raw = params.require(:spending_entry).permit(:spending_category_id, :amount_euros, :description, :period)
    {
      spending_category_id: raw[:spending_category_id],
      amount_cents:         (raw[:amount_euros].to_f * 100).round,
      description:          raw[:description].presence
    }
  end

  def compute_category_totals
    today       = Date.today
    week_range  = today.beginning_of_week..today.end_of_week
    month_range = today.beginning_of_month..today.end_of_month

    @weekly_total  = @category.spending_entries.where(spent_on: week_range).sum(:amount_cents)
    @monthly_total = @category.spending_entries.where(spent_on: month_range).sum(:amount_cents)
    @yearly_total  = @yearly ? @category.spending_entries.where(spent_on: today.beginning_of_year..today.end_of_year).sum(:amount_cents) : nil
    @entries       = @category.spending_entries.where(spent_on: month_range).order(spent_on: :desc)
  end
end
```

- [ ] **Step 4: Create Turbo Stream templates**

Create `app/views/spending_entries/create.turbo_stream.erb`:

```erb
<%= turbo_stream.replace "spending_category_stats_#{@entry.spending_category_id}" do %>
  <%= render "spending/category_stats",
        category: @category,
        weekly_total: @weekly_total,
        monthly_total: @monthly_total,
        yearly_total: @yearly_total,
        yearly: @yearly %>
<% end %>
<%= turbo_stream.prepend "spending_category_entries_#{@entry.spending_category_id}" do %>
  <%= render "spending/entry_row", entry: @entry, yearly: @yearly %>
<% end %>
<%= turbo_stream.replace "quick_add_form" do %>
  <%= render "spending/quick_add_form",
        categories: SpendingCategory.order(:name),
        yearly: @yearly %>
<% end %>
```

Create `app/views/spending_entries/destroy.turbo_stream.erb`:

```erb
<%= turbo_stream.replace "spending_category_stats_#{@category.id}" do %>
  <%= render "spending/category_stats",
        category: @category,
        weekly_total: @weekly_total,
        monthly_total: @monthly_total,
        yearly_total: @yearly_total,
        yearly: @yearly %>
<% end %>
<%= turbo_stream.remove "spending_entry_#{@entry.id}" %>
```

- [ ] **Step 5: Run tests — expect pass**

```bash
bin/rails test test/controllers/spending_entries_controller_test.rb
```

Expected: all 5 tests pass.

- [ ] **Step 6: Run the full test suite**

```bash
bin/rails test
```

Expected: all tests pass with no failures.

- [ ] **Step 7: Commit**

```bash
git add app/controllers/spending_entries_controller.rb app/views/spending_entries/ test/controllers/spending_entries_controller_test.rb
git commit -m "Add SpendingEntriesController with Turbo Stream templates"
```

---

## Task 10: Stimulus spending_card_controller.js

**Files:**
- Create: `app/javascript/controllers/spending_card_controller.js`

- [ ] **Step 1: Create the Stimulus controller**

Create `app/javascript/controllers/spending_card_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header", "editForm", "entries", "chevron"]

  toggleEntries() {
    const open = this.entriesTarget.classList.contains("hidden")
    this.entriesTarget.classList.toggle("hidden", !open)
    if (this.hasChevronTarget) {
      this.chevronTarget.style.transform = open ? "rotate(180deg)" : ""
    }
  }

  startEdit() {
    this.headerTarget.classList.add("hidden")
    this.editFormTarget.classList.remove("hidden")
  }

  cancelEdit() {
    this.editFormTarget.classList.add("hidden")
    this.headerTarget.classList.remove("hidden")
  }
}
```

- [ ] **Step 2: Verify Stimulus auto-discovery picks it up**

```bash
bin/rails assets:precompile 2>&1 | tail -5
```

Expected: no errors, `spending_card_controller` appears in compiled output.

- [ ] **Step 3: Commit**

```bash
git add app/javascript/controllers/spending_card_controller.js
git commit -m "Add spending_card Stimulus controller for expand/edit toggle"
```

---

## Task 11: Navigation — Add Spending to Sidebar and Mobile Nav

**Files:**
- Modify: `app/views/layouts/application.html.erb`

- [ ] **Step 1: Add Spending link to the desktop sidebar**

In `app/views/layouts/application.html.erb`, find the Properties nav link block (lines ~62–68) and add the following **after** it:

```erb
          <%= link_to spending_path,
              class: "flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-150 #{current_page?(spending_path) ? 'bg-emerald-500/10 text-emerald-400' : 'text-slate-400 hover:text-white hover:bg-slate-800/60'}" do %>
            <svg class="w-5 h-5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 00-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75"/>
            </svg>
            Spending
          <% end %>
```

- [ ] **Step 2: Add Spending link to the mobile bottom nav**

In the same file, find the mobile bottom nav Properties link block (lines ~129–135) and add the following **after** it:

```erb
          <%= link_to spending_path,
              class: "flex-1 flex flex-col items-center gap-1 py-3 text-xs font-medium transition-colors #{current_page?(spending_path) ? 'text-emerald-400 nav-active-indicator' : 'text-slate-500'}" do %>
            <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 00-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75"/>
            </svg>
            <span>Spending</span>
          <% end %>
```

- [ ] **Step 3: Run the full test suite**

```bash
bin/rails test
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add app/views/layouts/application.html.erb
git commit -m "Add Spending to desktop sidebar and mobile bottom nav"
```

---

## Task 12: Seed Spending Categories

**Files:**
- Modify: `db/seeds.rb`

- [ ] **Step 1: Add spending categories to seeds**

Open `db/seeds.rb` and append after the existing seed data:

```ruby
# ── Spending categories ───────────────────────────────────────────────────────

SpendingEntry.destroy_all
SpendingCategory.destroy_all

[
  { name: "Supermarket",    weekly_target_cents: 10_000, monthly_target_cents: 40_000 },
  { name: "Coffee & Cafes", weekly_target_cents:  2_500, monthly_target_cents: 10_000 },
  { name: "Dining Out",     weekly_target_cents:  5_000, monthly_target_cents: 20_000 },
  { name: "Transport",      weekly_target_cents:  3_000, monthly_target_cents: 12_000 },
  { name: "Misc",           weekly_target_cents: nil,    monthly_target_cents: nil     }
].each { |attrs| SpendingCategory.create!(attrs) }

# Sample entries spread across this week and month
supermarket = SpendingCategory.find_by(name: "Supermarket")
coffee      = SpendingCategory.find_by(name: "Coffee & Cafes")
dining      = SpendingCategory.find_by(name: "Dining Out")

[
  { spending_category: supermarket, amount_cents: 3_450, spent_on: Date.today,                   description: "Weekly shop" },
  { spending_category: supermarket, amount_cents: 1_200, spent_on: Date.today - 3,               description: "Top-up" },
  { spending_category: coffee,      amount_cents:   380, spent_on: Date.today,                   description: nil },
  { spending_category: coffee,      amount_cents:   420, spent_on: Date.today - 1,               description: nil },
  { spending_category: dining,      amount_cents: 4_800, spent_on: Date.today.beginning_of_week, description: "Dinner" }
].each { |attrs| SpendingEntry.create!(attrs) }
```

- [ ] **Step 2: Run seeds**

```bash
bin/rails db:seed
```

Expected: completes with no errors.

- [ ] **Step 3: Commit**

```bash
git add db/seeds.rb
git commit -m "Add spending categories and sample entries to seeds"
```

---

## Self-Review Checklist

**Spec coverage:**
- [x] Two new tables with all required columns, constraints, and indexes
- [x] Flexible user-defined categories
- [x] Weekly + monthly targets (optional)
- [x] Quick-add form: amount + category, description optional
- [x] `spent_on` defaults to today — no date picker
- [x] Category cards with progress bars (emerald/amber/red)
- [x] Expanded state: entry list + week-by-week breakdown
- [x] Turbo Stream partial strategy: `_stats_<id>` and `_entries_<id>` as separate targets
- [x] All 5 `.turbo_stream.erb` templates named and implemented
- [x] `respond_to` with `turbo_stream` + `html` fallback in all mutating actions
- [x] `period` hidden field passed through quick-add form and category edit form
- [x] N+1-free `SpendingController#index` using bulk GROUP BY queries
- [x] Week boundary: Monday (Rails `beginning_of_week` default)
- [x] Progress bar division-by-zero guard in helper
- [x] `resources` route helpers (not ad-hoc routes)
- [x] Named `as: :spending` route
- [x] Nav updated in both desktop sidebar and mobile bottom nav
- [x] Alphabetical category sort
- [x] Seeds include spending categories
- [x] All model and controller tests

**Placeholder scan:** None found.

**Type consistency:** `weekly_target_euros` / `monthly_target_euros` / `amount_euros` are form field names only — converted to cents in `category_params` and `entry_params` before hitting the model. `weekly_target_cents` / `monthly_target_cents` / `amount_cents` are the model attributes. Consistent throughout.
