module AdminIt
  module ActiveRecordData
    #
    module SingleContext
      protected

      def load_entity(identity: nil)
        identity ||= controller.params[:id]
        entity = entity_class.find(identity)
        controller.authorize(entity, "#{name}?") if AdminIt::Env.pundit?
        if child?
          fields
            .select { |f| f.type == :relation &&
                          f.assoc.klass == parent.entity_class }
            .each do |f|
              if f.assoc.collection?
                entity.send(f.name) << parent.entity
              else
                entity.send("#{f.name}=", parent.entity)
              end
            end
        end
        entity
      end
    end

    #
    module SavableSingleContext
      protected

      def do_save_entity
        if AdminIt::Env.pundit?
          controller.authorize(entity, "#{self.class.save_action}?")
        end
        params = controller.params[resource.name]
        fields(scope: :writable).each do |field|
          next unless params.key?(field.name)
          next unless field.writable?
          field.write(entity, params[field.name])
        end
        controller.redirect_to_default if entity.save
      end

      def add_child_context(for_resource, context_class: :table)
        child_resource = AdminIt.resources[for_resource]
        return nil if child_resource.nil?
        child_resource[context_class].new(self)
      end
    end

    #
    module NewContext
      def self.included(base)
        base.after_initialize do
          if child?
            fields
              .select { |f| f.type == :relation &&
                            f.assoc.klass == parent.entity_class }
              .each do |f|
                if f.assoc.collection?
                  entity.send(f.name) << parent.entity
                else
                  entity.send("#{f.name}=", parent.entity)
                end
                f.visible = false
              end
          end
        end
      end

      protected

      def load_entity(identity: nil)
        entity = entity_class.new
        controller.authorize(entity, "#{name}?") if AdminIt::Env.pundit?
        entity
      end
    end

    #
    module ShowContext
      def identity
        entity.id
      end

      protected

      def do_destroy_entity
        controller.authorize(entity, :destroy?) if AdminIt::Env.pundit?
        controller.redirect_to_default if entity.destroy
      end
    end

    #
    module EditContext
      def identity
        entity.id
      end
    end
  end
end
