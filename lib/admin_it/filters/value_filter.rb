module AdminIt
  class ValueFilter < FieldFilter
    attr_reader :values

    def initialize
      @values = []
    end

    before_save do |arguments: [], options: {}|
      arguments.concat(@values.map { |v| create_argument(v) })
    end

    after_load do |arguments: [], options: {}|
      unless arguments.empty?
        @values = arguments.map { |v| parse_argument(v) }.uniq
      end
      if options.key?(:add)
        @values.concat(options[:add].map { |v| parse_argument(v) }).uniq!
      elsif options.key?(:remove)
        options[:remove].each do |remove|
          @values.delete_if { |v| v == parse_argument(remove) }
        end
      end
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
