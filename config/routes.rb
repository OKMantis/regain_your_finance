Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#index"

  get "details",    to: "details#index",    as: :details
  get "properties", to: "properties#index", as: :properties

  resources :line_items, only: [ :update ]
  resources :property_expenses, only: [ :update ]

  get "spending", to: "spending#index", as: :spending
  resources :spending_categories, only: [ :create, :update, :destroy ]
  resources :spending_entries,    only: [ :create, :destroy ]
end
