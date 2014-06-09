#
module AdminIt
  #
  class Engine < Rails::Engine
#    paths['app/controllers'] = File.join('lib', 'admin_it', 'controllers')

    config.to_prepare do
      Rails.application.config.i18n.load_path +=
        Dir[Engine.root.join('lib', 'admin_it', 'locales', '*.yml')]
      unless File.basename($PROGRAM_NAME) == 'rake' &&
             ARGV.include?('db:migrate')
        Dir[File.join(AdminIt.config.root, '**', '*.rb')].each do |file|
          require file
        end
      end
      # Assets.register(Rails.application.assets)

      ActionController::Base.module_eval do
        prepend_view_path File.join('lib', 'views')
      end
    end

    config.app_middleware.insert_after(Rack::ETag, Middleware)
    config.assets.precompile += ['admin_it/index.js', 'admin_it/index.css']
  end

  def self.config
    config = AdminIt::Config
    yield config if block_given?
    config
  end
end
