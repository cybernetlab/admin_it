module AdminIt
  class SingleContext < Context
    @entity_getter = nil
    @entity_saver = nil
    @entity_destroyer = nil

    class << self
      attr_reader :entity_getter, :entity_saver, :entity_destroyer

      def copy
        proc do |source|
          if source <= SingleContext
            @entity_getter = source.entity_getter
            @entity_saver = source.entity_saver
            @entity_destroyer = source.entity_destroyer
          end
        end
      end

      def entity(&block)
        return unless block_given?
        @entity_getter = block
      end

      def save(&block)
        return unless block_given?
        @entity_saver = block
      end

      def destroy(&block)
        return unless block_given?
        @entity_destroyer = block
      end

      def section(title, *args)
        @sections ||= []
        @sections << [title].concat(args.select { |a| !find_field(a).nil? })
      end

      def single?
        true
      end

      def path(entity)
        AdminIt::Engine.routes.url_helpers.send(
          "#{resource.name}_path",
          entity
        )
      end

      protected

      def load_context(context, controller)
        context.entity =
          if context.entity_getter.nil?
            getter = "#{context.resource.name}_#{context.name}_entity".to_sym
            if controller.respond_to?(getter)
              controller.send(getter)
            else
              getter = "#{context.name}_entity"
              if controller.respond_to?(getter)
                controller.send(getter, context.entity_class)
              else
                context.class.load_entity(controller)
              end
            end
          else
            context.entity_getter.call(controller.params)
          end
      end

      def load_entity(controller)
        []
      end
    end

    class_attr_reader :entity_getter, :entity_saver, :entity_destroyer
    attr_accessor :entity

    def values
      return {} if @entity.nil?
      Hash[fields(scope: :readable).map { |f| [f.name, f.read(@entity)] }]
    end

    def path(entity)
      self.class.path(entity)
    end
  end

  class SavableSingleContext < SingleContext
    class << self
      def save_action; end

      protected

      def save_entity(entity, controller); end
    end

    def save_entity(controller)
      if entity_saver.nil?
        if controller.respond_to?("#{resource.name}_save")
          controller.send("#{resource.name}_save", name)
        elsif controller.respond_to?(:save)
          controller.save(entity_class, name)
        else
          self.class.save_entity(entity, controller)
        end
      else
        entity_saver.call(controller, name)
      end
    end

    class_attr_reader :save_action
  end

  class EditContext < SavableSingleContext
    class << self
      def path(entity)
        AdminIt::Engine.routes.url_helpers.send(
          "edit_#{resource.name}_path", entity
        )
      end

      def save_action
        :update
      end

      protected

      def default_icon
        'pencil'
      end
    end
  end

  class ShowContext < SingleContext
    class << self
      protected

      def destroy_entity(entity, controller); end

      def default_icon
        'info-circle'
      end
    end

    def destroy_entity(controller)
      if entity_destroyer.nil?
        if controller.respond_to?("#{resource.name}_destroy")
          controller.send("#{resource.name}_destroy")
        elsif controller.respond_to?(:destroy_entity)
          controller.destroy_entity(entity_class)
        else
          self.class.destroy_entity(entity, controller)
        end
      else
        entity_destroyer.call(controller)
      end
    end
  end

  class NewContext < SavableSingleContext
    class << self
      def path
        AdminIt::Engine.routes.url_helpers.send("new_#{resource.name}_path")
      end

      def save_action
        :create
      end
    end
  end
end
