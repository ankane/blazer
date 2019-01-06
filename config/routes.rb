Blazer::Engine.routes.draw do
  resources :queries, except: [:index] do
    post :run, on: :collection # err on the side of caution
    post :cancel, on: :collection
    post :refresh, on: :member
    get :tables, on: :collection
    get :docs, on: :collection
    get :more, on: :collection
  end

  resources :checks, except: [:show] do
    get :run, on: :member
  end

  get "dashboards", to: "queries#home"
  get "queries", to: "queries#home"

  resources :dashboards, except: [:index] do
    post :refresh, on: :member
  end

  root to: "queries#home"
end
