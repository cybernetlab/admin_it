# require 'simple-navigation'
# SimpleNavigation.config_file_paths << File.expand_path(File.join(%w(.. .. config)), __FILE__)

module AdminIt
  class Engine < Rails::Engine
#    paths['app/controllers'] = File.join('lib', 'admin_it', 'controllers')

    config.to_prepare do
      Rails.application.config.i18n.load_path +=
        Dir[Engine.root.join('lib', 'admin_it', 'locales', '*.yml')]

      unless File.basename($0) == "rake" && ARGV.include?("db:migrate")
        Dir[File.join(AdminIt.config.root, '**', '*.rb')].each do |file|
          require file
        end
      end
#      Assets.register(Rails.application.assets)

#      AdminIt.init

      Engine.routes.draw do
        AdminIt.resources.each do |name, resource|
          resources(resource.plural,
                    controller: "admin_it/#{name}",
                    except: [:index]) do
            resource.collections.each do |context|
              next unless context.collection?
              get context.context_name, on: :collection
            end
            unless resource.collections.empty?
              get('/', on: :collection, action: resource.default_context)
            end
          end
        end
        unless AdminIt.resources.empty?
          name, resource = AdminIt.resources.first
          get('/',
              controller: "admin_it/#{name}",
              action: resource.default_context)
        end
      end

      #AdminIt.compile_menu

      ActionController::Base.module_eval do
        prepend_view_path 'lib/views'
      end
    end
  end

  def self.config
    config = AdminIt::Config
    yield config if block_given?
    config
  end
end
