Blazer::Engine.routes.draw do
  root "queries#home"
  get "*path" => "queries#home", constraints: -> (req) { req.format == :html }

  resources :queries, except: [:new] do
    post :run, on: :collection # err on the side of caution
    post :refresh, on: :member
    get :tables, on: :collection
  end
  resources :checks, except: [:new, :show] do
    get :run, on: :member
  end
  resources :dashboards, except: [:new] do
    post :refresh, on: :member
  end
end
