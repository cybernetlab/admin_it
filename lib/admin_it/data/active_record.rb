require File.join %w(extend_it class)

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

      protected

      def default_fields(&block)
        enum = Enumerator.new do |yielder|
          exclude = []
          entity_class.reflections.each do |name, a|
            f = AdminIt::Field.create(name, entity_class, type: :relation)
            f.assoc = a
            yielder << f
            exclude << "#{name}_id" if a.belongs_to?
          end
          entity_class.columns_hash.each do |name, c|
            next if exclude.include?(name)
            name = name.to_sym
            opts = { type: c.type }
            if name == :id
              opts[:visible] = false
              opts[:writable] = false
            end
            yielder << AdminIt::Field.create(name, entity_class, opts)
          end
        end
        block_given? ? enum.each(&block) : enum
      end

      def default_filters
        enum = Enumerator.new do |yielder|
          fields.each do |field|
            next if field.type == :relation
            name = "#{field.field_name}_value"
            yielder << AdminIt::ValueFilter.create(name, self, field)
          end
        end
        block_given? ? enum.each(&block) : enum
      end
    end

    module CollectionContext
      def entities=(value)
        super(value)
        @count = value.count
      end

      protected

      def load_entities
        collection =
          if AdminIt::Env.pundit?
            controller.policy_scope(entity_class)
          else
            entity_class.all
          end
        if child?
          collection = collection.where(parent.resource.name => parent.entity)
        end
        sort = {}
        sorting.each do |_sort|
          name, order = _sort.split(':')
          sort[name.to_sym] = order.to_sym
        end
        collection = collection.order(sort) unless sort.empty?
        collection
      end
    end

    module SingleContext
      protected

      def load_entity(identity: nil)
        identity ||= controller.params[:id]
        entity = entity_class.find(identity)
        if AdminIt::Env.pundit?
          controller.authorize(entity, "#{name}?")
        end
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

    module SavableSingleContext
      protected

      def save_entity
        if AdminIt::Env.pundit?
          controller.authorize(entity, "#{self.class.save_action}?")
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

      def add_child_context(for_resource, context_class: :table)
        child_resource = AdminIt.resources[for_resource]
        return nil if child_resource.nil?
        child_resource[context_class].new(self)
      end
    end

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
        if AdminIt::Env.pundit?
          controller.authorize(entity, "#{name}?")
        end
        entity
      end
    end

    module ShowContext
      def identity
        entity.id
      end

      protected

      def destroy
        if AdminIt::Env.pundit?
          controller.authorize(entity, :destroy?)
        end
        if entity.destroy
          controller.redirect_to_default
        end
      end
    end

    module EditContext
      def identity
        entity.id
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
      def self.included(base)
        base.class_eval do
          class << self
            attr_accessor :assoc

            protected

            def default_display_name
              entity_class.human_attribute_name(field_name)
            end
          end
          class_attr_reader :assoc
        end
      end

      protected

      def read_value(entity)
        value = entity.send(name)
        if type == :relation
          assoc.collection? ? value.map(&:id).to_json : value.id
        else
          value
        end
      end

      def show_value(entity)
        value = entity.send(name)
        if type == :relation
          resource = AdminIt.resources.values.find do |r|
            r.entity_class == assoc.klass
          end
          return I18n.t('admin_it.relation.no_resource') if resource.nil?
          context = resource.contexts.find { |c| c <= ShowContext }
          return I18n.t('admin_it.relation.no_context') if context.nil?
          if assoc.collection?
            if value.count == 0
              I18n.t('admin_it.collection.no_data')
            else
              context.read(value.first) + ' ...'
            end
          else
            context.read(value)
          end
        else
          value
        end
      end

      def write_value(entity, value)
        entity.send("#{name}=", value)
      end
    end

    module ValueFilter
      def all_values(collection = nil, &block)
        enum = Enumerator.new do |yielder|
          field
            .entity_class
            .select(self.class.field.field_name)
            .group(self.class.field.field_name)
            .count
            .each do |v, c|
              yielder << { value: v, count: c }
            end
        end
        block_given? ? enum.each(&block) : enum
      end

      def apply(collection)
        return collection if @values.empty?
        binding = []
        conditions = ''
        if @values.size == 1 && @values[0].nil?
          conditions = "#{field.field_name} IS NULL"
        else
          conditions = "#{field.field_name} IN (?)"
          binding << @values.select { |v| !v.nil? }
          if @values.any? { |v| v.nil? }
            conditions += " OR #{field.field_name} IS NULL"
          end
        end
        collection = collection.where(conditions, *binding)
      end
    end
  end
end
