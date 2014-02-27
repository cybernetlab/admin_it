module AdminIt
  module ObjectData
    module Context
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def load_fields
          all = entity_class.instance_methods(false) - Object.instance_methods
          getters = all.select do |m|
            m.to_s =~ /\w\z/ && entity_class.instance_method(m).arity == 0
          end
          setters = all.select do |m|
            m.to_s[-1] == '=' && entity_class.instance_method(m).arity == 1
          end
          fields = getters.map do |m|
            AdminIt::Field.new(
              m,
              entity_class,
              read: true,
              write: setters.include?("#{m}=".to_sym)
            ).extend(Field)
          end
          setters.reject! { |m| getters.include?(m.to_s[0..-2].to_sym) }
          fields.concat(setters.map do |m|
            name = m.to_s[0..-2].to_sym
            AdminIt::Field.new(
              name,
              entity_class,
              read: false,
              write: true
            ).extend(Field)
          end)
        end
      end
    end

    module Field
      protected

      def read_value(entity)
        entity.send(name)
      end

      def write_value(entity, value)
        entity.send("#{name}=", value)
      end
    end
  end
end
