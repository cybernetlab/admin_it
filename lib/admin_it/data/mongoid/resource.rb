require 'bson'
require 'moped'

module AdminIt
  module MongoidData
    #
    module Resource
      protected

      TYPE_MAPPING = {
        Array => :array,
        BigDecimal => :float,
        Boolean => :boolean,
        Date => :date,
        DateTime => :datetime,
        Float => :float,
        Hash => :hash,
        Integer => :integer,
        BSON::ObjectId => :integer,
        BSON::Binary => :binary,
        Range => :range,
        Regexp => :regexp,
        String => :string,
        Symbol => :symbol,
        Time => :time
      }

      NONFILTER_TYPES = %i(array hash binary range regexp relation)

      def default_fields(&block)
        enum = Enumerator.new do |yielder|
          entity_class.fields.each do |name, field|
            name = name.to_sym
            opts = { type: TYPE_MAPPING[field.options[:type]] }
            if name == :_id
              name = :id
              opts[:visible] = false
              opts[:writable] = false
            end
            yielder << AdminIt::Field.create(name, entity_class, opts)
          end
          relations = entity_class.relations
          relations.merge!(entity_class.embedded_relations)
          relations.each do |name, rel|
            name = name.to_sym
            opts = { type: :relation }
            field = AdminIt::Field.create(name, entity_class, opts)
            field.assoc = rel
            yielder << field
          end
        end
        block_given? ? enum.each(&block) : enum
      end

      def default_filters
        enum = Enumerator.new do |yielder|
          fields.each do |field|
            next if NONFILTER_TYPES.include?(field.type)
            name = "#{field.field_name}_value"
            yielder << AdminIt::ValueFilter.create(name, self, field)
          end
        end
        block_given? ? enum.each(&block) : enum
      end
    end
  end
end
