# Spending Log — Design Spec

**Date:** 2026-05-30
**Status:** Reviewed

## Overview

A new Spending page for logging and tracking discretionary expenses (supermarket, coffee, dining, etc.) against weekly and monthly budgets. Categories are user-defined and flexible. Entry is optimised for quick mobile use: amount + category, description optional.

---

## Data Model

### `spending_categories`

| column | type | notes |
|---|---|---|
| `name` | string | required, unique |
| `weekly_target_cents` | integer | nullable — target is optional |
| `monthly_target_cents` | integer | nullable |
| `timestamps` | datetime | |

`name` has a unique index. Model validates `name: { presence: true, uniqueness: true }`.

### `spending_entries`

| column | type | notes |
|---|---|---|
| `spending_category_id` | bigint | FK, not null |
| `amount_cents` | integer | not null, >= 0 |
| `description` | string | optional |
| `spent_on` | date | not null, defaults to today |
| `timestamps` | datetime | |

**Indexes:**
- `spending_entries(spending_category_id)` — FK index
- `spending_entries(spent_on)` — date range queries
- `spending_entries(spending_category_id, spent_on)` — composite; used by every progress-bar aggregate query

`SpendingEntry` belongs_to `SpendingCategory`. Destroying a category cascades to its entries (`dependent: :destroy`).

Week number and month are derived from `spent_on` at query time — no stored computed columns.

**Week boundary:** Monday is the start of the week (ISO week, `Date#beginning_of_week` default in Rails).

Weekly totals: `SUM(amount_cents) WHERE spent_on BETWEEN monday AND sunday`
Monthly totals: `SUM(amount_cents) WHERE spent_on BETWEEN month_start AND month_end`

Progress bar percentage guard: `target.zero? || target.nil? ? nil : (spent * 100.0 / target)` — nil means no colour.

**Controller query pattern (no N+1):** `SpendingController#index` loads all categories, then runs two aggregate queries (`WHERE spent_on BETWEEN ... GROUP BY spending_category_id`) and merges the results in Ruby. Same pattern as `DashboardController` using `.group(:category).sum(...)`.

---

## Pages & Controllers

### New routes

```ruby
get  "spending", to: "spending#index", as: :spending
resources :spending_categories, only: [:create, :update, :destroy]
resources :spending_entries,    only: [:create, :destroy]
```

### Controllers

- `SpendingController#index` — loads all categories alphabetically with current week/month totals merged in Ruby
- `SpendingCategoriesController` — create, update, destroy; all actions respond to `turbo_stream` and `html` formats
- `SpendingEntriesController` — create, destroy; same dual-format respond_to

All mutating actions use `respond_to` blocks:

```ruby
respond_to do |format|
  format.turbo_stream { render "action_name" }  # renders action_name.turbo_stream.erb
  format.html         { redirect_to spending_path }
end
```

Required Turbo Stream templates:
- `spending_entries/create.turbo_stream.erb`
- `spending_entries/destroy.turbo_stream.erb`
- `spending_categories/create.turbo_stream.erb`
- `spending_categories/update.turbo_stream.erb`
- `spending_categories/destroy.turbo_stream.erb`

---

## UI Layout

### Navigation

Add "Spending" to both the desktop sidebar and mobile bottom nav. Use a wallet or shopping-bag icon. Nav active state follows the existing emerald highlight pattern.

### Quick-add bar (top of page)

A persistent inline form always visible at the top:
- Category dropdown — defaults to first category alphabetically (no client-side persistence)
- Amount input (euros, converted to cents on submit)
- Description field (optional, placeholder-only — always visible, not collapsible)
- `period` as a hidden field (`params[:period]`) so Turbo Stream responses render in the correct mode
- "Add" button

Submits via Turbo Stream. On success: clears amount + description, keeps category selected, updates the relevant card's **progress bar region only** (not the whole card — see Turbo Stream partial strategy below).

### Category cards (middle)

One card per `SpendingCategory`, sorted alphabetically.

Each card shows:
- Category name
- Edit controls (pencil + delete icons, visible on hover/long-press)
- Weekly progress bar: `€X spent of €Y target` (or `€X this week` if no target)
- Monthly progress bar: same pattern
- Progress bar colour: emerald (< 80% of target), amber (80–99%), red (≥ 100%). No colour when no target is set.

**Expanded state** (Stimulus toggle, no page reload):
- List of entries for the current month, newest first: date | amount | description | delete button
- Week-by-week breakdown table: week label | spent | target | diff

### Turbo Stream partial strategy

Each card is split into two independently targetable regions:

1. **`spending_category_stats_<id>`** — progress bars and totals only. Replaced by Turbo Stream on entry create/destroy. This region is always re-rendered; it does not contain toggle state.
2. **`spending_category_entries_<id>`** — the expanded entry list and week breakdown. Only replaced when an entry in this category is added or deleted, and only if the list is present in the DOM (i.e. the card is currently expanded). The Stimulus controller manages the open/closed toggle via a `data-open` attribute on the card element; Turbo Stream updates do not touch this attribute, so the expanded state is preserved.

Category inline edit (pencil → form swap) is handled entirely by Stimulus on the card header element. Saving triggers a `SpendingCategoriesController#update` that replaces the entire card (`spending_category_<id>`) via Turbo Stream, which is acceptable because the edit form is closed by the time the response arrives.

### New category (bottom)

A "+ New category" button that opens an inline form: name (required), weekly target (optional), monthly target (optional). Submits via Turbo Stream, appends card to the list.

### Period toggle

Respects the existing `?period=yearly` query param. In yearly mode:
- Monthly bars replaced with year-to-date total vs. 12× monthly target
- `period` param passed as hidden field in the quick-add form so stream responses render correctly

### Empty states

- No categories: centred prompt — "Add your first spending category to start tracking"
- Category with no entries this period: progress bars show €0 / target

---

## Interactions

### Adding an entry

1. User selects category, enters amount, optional description, submits
2. `SpendingEntriesController#create` saves entry with `spent_on: Date.today`
3. Turbo Stream replaces `spending_category_stats_<id>` (progress bars) and, if the card is expanded, appends to `spending_category_entries_<id>` (entry list)

### Editing a category

Clicking pencil swaps card header into inline edit form (Stimulus, `inline_edit_controller.js` or a new `spending_card_controller.js`). Saving patches via `SpendingCategoriesController#update`, which replaces the full card DOM node (`spending_category_<id>`) — acceptable because the inline edit form is the active state and closes on save.

### Deleting a category

Browser `confirm()` dialog. Cascades to all entries. Turbo Stream removes the card element.

### Deleting an entry

Turbo Stream removes the entry row from `spending_category_entries_<id>` and replaces `spending_category_stats_<id>` to refresh the totals.

---

## Constraints & Decisions

- **No date editing on entries** — entries always log to today. Can be added later.
- **No entry editing** — delete and re-add. Keeps the UI simple.
- **Targets are optional** — categories work as pure logs without a target set.
- **Category order** — alphabetical. No drag-to-reorder for MVP.
- **Default category selection** — first alphabetically. No cookie or session persistence for MVP.
- **Week boundary** — Monday (Rails `beginning_of_week` default / ISO week).
- **Monetary storage** — cents integers, consistent with the rest of the app.
- **Display** — euros, `number_with_delimiter` with `.` thousands separator, `€` prefix.
- **Turbo Stream + HTML fallback** — all mutating actions respond to both formats.
