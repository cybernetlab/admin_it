module AdminIt
  module ActiveRecordData
    #
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
          if assoc.collection?
            value.nil? || value.empty? ? [] : value.map(&:id).to_json
          else
            value.nil? ? nil : value.id
          end
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
              v = context.read(value.first)
              v.nil? ? '' : context.read(value.first) + ' ...'
            end
          else
            context.read(value)
          end
        else
          value
        end
      end

      def write_value(entity, value)
        if type == :relation
          if assoc.collection?
            value.map! { |x| assoc.klass.find(x) }
          else
            value = assoc.klass.find(value)
          end
        end
        entity.send("#{name}=", value)
      end
    end
  end
end
