# Spending Log — Design Spec

**Date:** 2026-05-30
**Status:** Approved

## Overview

A new Spending page for logging and tracking discretionary expenses (supermarket, coffee, dining, etc.) against weekly and monthly budgets. Categories are user-defined and flexible. Entry is optimised for quick mobile use: amount + category, description optional.

---

## Data Model

### `spending_categories`

| column | type | notes |
|---|---|---|
| `name` | string | required |
| `weekly_target_cents` | integer | nullable — target is optional |
| `monthly_target_cents` | integer | nullable |
| `timestamps` | datetime | |

### `spending_entries`

| column | type | notes |
|---|---|---|
| `spending_category_id` | bigint | FK, not null |
| `amount_cents` | integer | required, >= 0 |
| `description` | string | optional |
| `spent_on` | date | defaults to today, not null |
| `timestamps` | datetime | |

`SpendingEntry` belongs_to `SpendingCategory`. Destroying a category cascades to its entries.

Week number and month are derived from `spent_on` at query time — no stored computed columns.

Weekly totals: `SUM(amount_cents) WHERE spent_on BETWEEN [week_start] AND [week_end]`
Monthly totals: `SUM(amount_cents) WHERE spent_on BETWEEN [month_start] AND [month_end]`

---

## Pages & Controllers

### New routes

```
get  "spending"                          → spending#index
post "spending_categories"               → spending_categories#create
patch/put "spending_categories/:id"      → spending_categories#update
delete "spending_categories/:id"         → spending_categories#destroy
post "spending_entries"                  → spending_entries#create
delete "spending_entries/:id"            → spending_entries#destroy
```

### Controllers

- `SpendingController#index` — loads all categories with their current week/month totals
- `SpendingCategoriesController` — create, update, destroy
- `SpendingEntriesController` — create, destroy

---

## UI Layout

### Navigation

Add "Spending" to both the desktop sidebar and mobile bottom nav. Use a wallet or shopping-bag icon. Nav active state follows the existing emerald highlight pattern.

### Quick-add bar (top of page)

A persistent inline form always visible at the top:
- Category dropdown (pre-selects last used category)
- Amount input (euros, converted to cents on submit)
- Description field (optional, collapsible or placeholder-only)
- "Add" button

Submits via Turbo Stream. On success: clears amount + description, keeps category selected, updates the relevant card in-place.

### Category cards (middle)

One card per `SpendingCategory`, sorted by most recently used. Each card shows:

- Category name
- Edit controls (pencil + delete icons, visible on hover/long-press)
- Weekly progress bar: `€X spent of €Y target` (or `€X this week` if no target)
- Monthly progress bar: same pattern
- Progress bar colour: emerald (< 80% of target), amber (80–99%), red (≥ 100%). No colour when no target is set.

**Expanded state** (Stimulus toggle, no page reload):
- List of entries for the current month, newest first: date | amount | description | delete button
- Week-by-week breakdown table: week label | spent | target | diff

### New category (bottom)

A "+ New category" button that opens an inline form: name (required), weekly target (optional), monthly target (optional). Submits via Turbo Stream, appends card to the list.

### Period toggle

Respects the existing `?period=yearly` query param. In yearly mode:
- Monthly bars replaced with year-to-date total vs. 12× monthly target

### Empty states

- No categories: centred prompt — "Add your first spending category to start tracking"
- Category with no entries this period: progress bars show €0 / target

---

## Interactions

### Adding an entry

1. User selects category, enters amount, optional description, submits
2. `SpendingEntriesController#create` saves entry with `spent_on: Date.today`
3. Turbo Stream updates: the relevant category card (totals + progress bars) and its expanded log if currently open

### Editing a category

Clicking pencil swaps card header into inline edit form (Stimulus). Saving updates via Turbo Stream in-place.

### Deleting a category

Browser confirm dialog. Cascades to all entries. Turbo Stream removes card.

### Deleting an entry

Turbo Stream removes entry row and refreshes the card's totals.

---

## Constraints & Decisions

- **No date editing on entries** — entries always log to today. Can be added later.
- **No entry editing** — delete and re-add. Keeps the UI simple.
- **Targets are optional** — categories work as pure logs without a target set.
- **Monetary storage** — cents integers, consistent with the rest of the app.
- **Display** — euros, `number_with_delimiter` with `.` thousands separator, `€` prefix.
