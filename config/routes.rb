Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"

  get    "/sign_in",  to: "sessions#new",     as: :sign_in
  post   "/sign_in",  to: "sessions#create"
  delete "/sign_out", to: "sessions#destroy", as: :sign_out

  resources :clients, only: [ :index, :show ]
  resources :email_threads, only: [ :show ]

  get  "/email_threads/:id/summary",         to: "email_summaries_web#show",    as: :email_summary_web
  post "/email_threads/:id/summary/refresh", to: "email_summaries_web#refresh", as: :refresh_email_summary_web

  get "/web/reports/firm",   to: "reports_web#firm",   as: :firm_report
  get "/web/reports/global", to: "reports_web#global",  as: :global_report

  get "/401", to: "errors#unauthorized"
  get "/403", to: "errors#forbidden"
  get "/404", to: "errors#not_found"
  get "/500", to: "errors#internal_server_error"

  post "/login", to: "auth#create"

  get  "/email_summaries/:conversation_id",         to: "email_summaries#show",    as: :email_summary
  post "/email_summaries/:conversation_id/refresh", to: "email_summaries#refresh", as: :refresh_email_summary

  get "/reports/firm",   to: "reports#firm"
  get "/reports/global", to: "reports#global"

  get  "/client_summaries/:client_id",         to: "client_summaries#show",    as: :client_summary_api
  post "/client_summaries/:client_id/refresh", to: "client_summaries#refresh", as: :refresh_client_summary_api

  get  "/clients/:id/summary",         to: "client_summaries_web#show",    as: :client_summary_web
  post "/clients/:id/summary/refresh", to: "client_summaries_web#refresh", as: :refresh_client_summary_web
end
