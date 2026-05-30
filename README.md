# Regain

A personal finance dashboard for tracking income, expenses, and property finances — built for clarity and daily use.

**[Live demo →](https://regain-your-finance.onrender.com)**

![Ruby](https://img.shields.io/badge/Ruby-3.3.5-CC342D?logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-8.1-CC0000?logo=rubyonrails&logoColor=white)

## Features

- **Dashboard** — monthly and yearly savings summary, savings rate bar, income and expense breakdown by category
- **Details** — full line-item list grouped by category with inline editing for names and amounts
- **Properties** — per-property income, expenses, and net figures across multiple real estate holdings
- **Spending** — category-based spending log with weekly and monthly budget targets, progress bars, and a per-entry history
- **Period toggle** — switch between monthly and yearly views on any page
- **Billing period normalization** — enter amounts as monthly, yearly, quarterly, bi-weekly, or weekly; the app converts everything to a monthly equivalent automatically
- **PWA** — installable on iOS and Android for quick access from the home screen
- **Responsive** — desktop sidebar layout, mobile bottom navigation

## Tech stack

- Ruby on Rails 8.1 · PostgreSQL
- Tailwind CSS · Hotwire (Turbo + Stimulus) · importmap · Propshaft
- Deployed on Render · Neon PostgreSQL

## Getting started

**Prerequisites:** Ruby 3.3.5, PostgreSQL

```bash
git clone https://github.com/OKMantis/regain_your_finance.git
cd regain_your_finance
bundle install
bin/rails db:create db:migrate
bin/dev
```

Open [http://localhost:3000](http://localhost:3000).

To seed your own data, edit `db/seeds.rb` and run `bin/rails db:seed`.

## Pages

| Page | Path | Description |
|------|------|-------------|
| Dashboard | `/` | Savings hero, savings rate, income and expense summary |
| Details | `/details` | All line items by category with inline editing |
| Properties | `/properties` | Real estate income, costs, and net per property |
| Spending | `/spending` | Spending categories with budget targets, weekly/monthly progress, and entry log |
