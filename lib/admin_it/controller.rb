module AdminIt
  module Controller
    def self.included(base)
      base.class_eval do
        attr_reader :context
        helper_method :context, :resource
        helper AdminIt::Helpers
        helper AdminIt::Engine.routes.url_helpers

        if AdminIt::Env.pundit?
          collections = @resource.collections.map(&:context_name)
          after_action :verify_authorized, except: collections
          after_action :verify_policy_scoped, only: collections
        end
      end
    end

    def resource
      self.class.instance_variable_get(:@resource)
    end

    def redirect_to_default
      redirect_to(resource[resource.default_context].path)
    end

    private

    def load_context(context_class)
      @context = context_class.new(self)
      yield if block_given?
      layout = ['admin_it', params[:layout]].compact.join('_')
      if !performed?
        if layout == 'admin_it' && !request.query_parameters.empty?
          redirect_to request.path
        else
          render template: "admin_it/#{context.name}", layout: layout
        end
      end
      @context.save
    end
  end
end
