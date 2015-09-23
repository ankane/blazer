module Blazer
  class Engine < ::Rails::Engine
    isolate_namespace Blazer

    initializer "blazer" do |app|
      # use a proc instead of a string
      app.config.assets.precompile << proc { |path| path =~ /\Ablazer\/application\.(js|css)\z/ }

      Blazer.time_zone ||= Time.zone
      Blazer.user_class ||= Devise.mappings.values[0].class_name rescue nil

      if Blazer.user_class
        Blazer.current_user_name = "current_#{Blazer.user_class.downcase.singularize}"
      end

      Blazer::Query.belongs_to :creator, class_name: Blazer.user_class.to_s if Blazer.user_class
    end
  end
end
