Blazer::Engine.routes.draw do
  resources :queries, except: [:index] do
    post :run, on: :collection # err on the side of caution
  end
  root to: "queries#index"
end
