module Blazer
  class Engine < ::Rails::Engine
    isolate_namespace Blazer

    initializer "precompile" do |app|
      # use a proc instead of a string
      app.config.assets.precompile << proc { |path| path =~ /\Ablazer\/application\.(js|css)\z/ }
    end
  end
end
