module AdminIt
  module HashData
    module Context
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def load_fields
          []
        end
      end
    end

    module Field
      protected

      def read_value(entity)
        entity[name]
      end

      def write_value(entity, value)
        entity[name] = value
      end
    end
  end
end
