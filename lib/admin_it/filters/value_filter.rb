module AdminIt
  class ValueFilter < FieldFilter
    attr_reader :values

    def initialize(*values, **opts)
      @values = values.map { |v| parse_argument(v) }.uniq
    end

    before_save do |arguments: [], options: {}|
      arguments.concat(@values.map { |v| create_argument(v) })
    end

    def change(str)
      return if str.nil? || !str.is_a?(String) || str.empty?
      @values = [] unless /[+\-]/ =~ str
      str.split(',').each do |param|
        param.strip!
        if param[0] == '-'
          @values.delete_if { |v| v == parse_argument(param[1..-1]) }
        else
          param = param[1..-1] if param[0] == '+'
          @values << parse_argument(param)
        end
      end
      @values.uniq!
    end

    def all_values(collection = nil, &block)
      collection ||= []
      enum = Enumerator.new do |yielder|
        values = collection.map { |e| self.class.field.read(e) }
        values.uniq.each do |value|
          yileder << {
            value: value, count: values.count { |v| v == value }
          }
        end
      end
      block_given? ? enum.each(&block) : enum
    end

    def value(val)
      create_argument(val)
    end

    def apply(collection)
      return collection if @values.empty?
      collection.select do |entity|
        @values.include?(self.class.field.read(entity))
      end
    end
  end
end
