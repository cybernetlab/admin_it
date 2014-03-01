module AdminIt
  module ActiveRecordData
    module Resource
      def display_name
        entity_class
          .model_name
          .human#(count: 0)
          .split(' ')
          .map { |s| s.mb_chars.capitalize }
          .join(' ')
      end
    end

    module Context
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        protected

        def load_fields
          columns = entity_class.columns_hash
          assoc = entity_class.reflections
          columns.map do |name, c|
            opts = { type: c.type }
            if name == 'id'
              opts[:visible] = false
              opts[:writable] = false
            end
            AdminIt::Field
              .new(name, entity_class, opts)
              .extend(ObjectData::Field)
              .extend(Field)
          end.concat(
            assoc.map do |name, a|
              AdminIt::Field
                .new(name, entity_class, type: :relation)
                .extend(ObjectData::Field)
                .extend(Field)
            end
          )
        end
      end
    end

    module CollectionContext
      def self.included(base)
        base.extend(ClassMethods)
      end

      def entities=(value)
        super(value)
        @count = value.count
      end

      module ClassMethods
        def load_entities(controller)
          if AdminIt::Env.pundit?
            controller.policy_scope(entity_class)
          else
            entity_class.all
          end
        end
      end
    end

    module SingleContext
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def load_entity(controller)
          entity = entity_class.find(controller.params[:id])
          if AdminIt::Env.pundit?
            controller.authorize(entity, "#{context_name}?")
          end
          entity
        end
      end
    end

    module SavableSingleContext
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def save_entity(entity, controller)
          if AdminIt::Env.pundit?
            controller.authorize(entity, "#{save_action}?")
          end

          params = controller.params[resource.name]

          fields(scope: :writable).each do |field|
            next unless params.key?(field.name)
            next unless field.writable?
            next if field.type == :relation
            field.write(entity, params[field.name])
          end

          if entity.save
            controller.redirect_to_default
          end
        end
      end
    end

    module NewContext
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def load_entity(controller)
          entity = entity_class.new
          if AdminIt::Env.pundit?
            controller.authorize(entity, "#{context_name}?")
          end
          entity
        end
      end
    end

    module ShowContext
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def destroy_entity(entity, controller)
          if AdminIt::Env.pundit?
            controller.authorize(entity, :destroy?)
          end

          if entity.destroy
            controller.redirect_to_default
          end
        end
      end
    end

    module TableContext
      def entities
        if @entities.count > page_size
          # limit collection to current page
          @entities = @entities
            .offset(page_size * (page - 1))
            .limit(page_size)
        end
        super
      end
    end

    module Field
      protected

      def default_display_name
        entity_class.human_attribute_name(name)
      end

      def read_value(entity)
        entity.send(name)
      end

      def write_value(entity, value)
        entity.send("#{name}=", value)
      end
    end
  end
end
