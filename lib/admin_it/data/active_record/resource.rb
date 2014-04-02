module AdminIt
  module ActiveRecordData
    #
    module Resource
      protected

      TYPE_MAPPING = {
        primary_key: :integer,
        string: :string,
        text: :string,
        integer: :integer,
        float: :float,
        decimal: :float,
        datetime: :datetime,
        timestamp: :datetime,
        time: :time,
        date: :date,
        binary: :binary,
        boolean: :boolean
      }

      def default_display_name
        entity_class
          .model_name
          .human# (count: 0)
          .split(' ')
          .map { |s| s.mb_chars.capitalize }
          .join(' ')
      end

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
            opts = { type: TYPE_MAPPING[c.type] }
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
  end
end
