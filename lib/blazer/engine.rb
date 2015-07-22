module Blazer
  class Engine < ::Rails::Engine
    isolate_namespace Blazer

    initializer "blazer" do |app|
      # use a proc instead of a string
      app.config.assets.precompile << proc { |path| path =~ /\Ablazer\/application\.(js|css)\z/ }

      Blazer.time_zone ||= Time.zone
      Blazer.user_class ||= User rescue nil
      Blazer::Query.belongs_to :creator, class_name: Blazer.user_class.to_s if Blazer.user_class
    end
  end
end
