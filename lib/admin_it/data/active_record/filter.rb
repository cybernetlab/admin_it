module AdminIt
  module ActiveRecordData
    #
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
        collection.where(conditions, *binding)
      end
    end
  end
end
