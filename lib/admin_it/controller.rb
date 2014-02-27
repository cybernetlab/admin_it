module AdminIt
  module Controller
    def self.included(base)
      base.class_eval do
        attr_reader :admin_context, :admin_action
        helper_method :admin_context, :admin_resource, :admin_action,
                      :admin_self_path
        helper AdminIt::Helpers
        helper AdminIt::Engine.routes.url_helpers

        if AdminIt::Env.pundit?
          col = @admin_resource.contexts.select { |_, c| c.collection? }
          after_action :verify_authorized, except: col.keys
          after_action :verify_policy_scoped, only: col.keys
        end
      end
    end

    def admin_resource
      self.class.instance_variable_get(:@admin_resource)
    end

    private

    def load_context(context, action)
      @admin_action = action
      @admin_context = context.load(self)

      yield if block_given?

      layout = ['admin_it', params[:layout]].compact.join('_')
      if !performed?
        if layout == 'admin_it' && !request.query_parameters.empty?
          redirect_to request.path
        else
          render template: "admin_it/#{admin_action}", layout: layout
        end
      end
      @admin_context.save
    end


    def redirect_to_default
      redirect_to(
        controller: admin_context.name,
        action: admin_resource.default_context
      )
    end

    def destroy_entity
    end
  end
end
