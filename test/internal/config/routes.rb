Rails.application.routes.draw do
  mount Blazer::Engine, at: "/"

  get Blazer.sharing.route_path, to: Blazer.sharing.to_controller, as: :share_query if Blazer.sharing.enabled?
end
