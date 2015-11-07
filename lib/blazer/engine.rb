module Blazer
  class Engine < ::Rails::Engine
    isolate_namespace Blazer

    initializer "blazer" do |app|
      # use a proc instead of a string
      app.config.assets.precompile << proc { |path| path =~ /\Ablazer\/application\.(js|css)\z/ }
      app.config.assets.precompile << proc { |path| path =~ /\Ablazer\/.+\.(eot|svg|ttf|woff)\z/ }

      Blazer.time_zone ||= Blazer.settings["time_zone"] || Time.zone
      Blazer.audit = Blazer.settings.key?("audit") ? Blazer.settings["audit"] : true
      Blazer.user_name = Blazer.settings["user_name"] if Blazer.settings["user_name"]
      Blazer.from_email = Blazer.settings["from_email"] if Blazer.settings["from_email"]

      Blazer.user_class ||= Blazer.settings.key?("user_class") ? Blazer.settings["user_class"] : (User rescue nil)
      Blazer.user_method = Blazer.settings["user_method"]
      if Blazer.user_class
        Blazer.user_method ||= "current_#{Blazer.user_class.to_s.downcase.singularize}"
      end

      Blazer::Query.belongs_to :creator, class_name: Blazer.user_class.to_s if Blazer.user_class

      Blazer.cache ||= Rails.cache
    end
  end
end
