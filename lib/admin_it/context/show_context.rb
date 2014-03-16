module AdminIt
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
      unless @read.nil?
        @read.call(entity)
      end
    end

    attr_reader :confirm

    after_load do |store: {}, params: {}|
      self.confirm = params[:confirm]
    end

    def confirm=(value)
      value = value.downcase.to_sym if value.is_a?(String)
      return unless value.is_a?(Symbol) && CONFIRMS.include?(value)
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
