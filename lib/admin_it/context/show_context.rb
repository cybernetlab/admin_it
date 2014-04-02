#
module AdminIt
  using EnsureIt if EnsureIt.refined?

  #
  class ShowContext < SingleContext
    extend Renderable
    include Identifiable

    CONFIRMS = %i(destroy update)

    class << self
      protected

      def default_icon
        'info-circle'
      end
    end

    dsl do
      dsl_block :read
    end

    def self.entity_path?
      true
    end

    def self.read(entity)
      @read.call(entity) unless @read.nil?
    end

    attr_reader :confirm

    after_load do |store: {}, params: {}|
      self.confirm = params[:confirm]
    end

    def confirm=(value)
      value = value.ensure_symbol(downcase: true, values: CONFIRMS) || return
      @confirm = value
    end

    def confirm?
      !@confirm.nil?
    end

    def destroy_entity
      if entity_destroyer.nil?
        if controller.respond_to?("#{resource.name}_destroy")
          controller.send("#{resource.name}_destroy")
        elsif controller.respond_to?(:destroy_entity)
          controller.destroy_entity(entity_class)
        else
          do_destroy_entity
        end
      else
        entity_destroyer.call(controller)
      end
    end

    protected

    def do_destroy_entity; end
  end
end
