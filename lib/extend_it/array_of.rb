require 'forwardable'
require File.join %w(extend_it ensures)
require File.join %w(extend_it asserts)

using ExtendIt::Ensures if ExtendIt.config.use_refines?

module ExtendIt
  module ArrayOf
    def array_of(entity_class, &block)
      array_name = "ArrayOf#{entity_class.name.split('::').last}"
      array_class = Class.new(SimpleDelegator) do
        @entity_class = entity_class
        @scopes = {}
        @finder = nil
        extend ArrayOf::ArrayClassMethods
        include ArrayOf::ArrayMethods
      end
      array_class.class_eval(&block) if block_given?
      const_set(array_name, array_class)
    end

    module ArrayClassMethods
      include Asserts

      attr_reader :scopes, :finder

      def select(arr)
        if arr.is_a?(self)
          arr.to_a
        else
          arr.select { |a| a.is_a?(@entity_class) }
        end
      end

      def entity?(obj)
        obj.is_a?(@entity_class)
      end

      def scope(*names, &block)
        names.flatten.uniq.each do |name|
          name = name.ensure_symbol || next
          @scopes[name] = block.nil? ? proc { |e| e.send(name) } : block
          str = name.to_s
          if str[-1] == '?'
            @scopes[str[0..-2].to_sym] = block.nil? ? proc { |e| e.send(name) } : block
          end
        end
      end

      def find_by(name, &block)
        assert_symbol(:name)
        @finder = block.nil? ? proc { |e| e.send(name) } : block
      end

      def has_finder?
        !@finder.nil?
      end
    end

    module ArrayMethods
      def initialize(*arr)
        @array = self.class.select(arr.flatten)
        super(@array)
      end

      def scope(name)
        if name.is_a?(Symbol)
          if self.class.scopes.include?(name)
            self.class.new(@array.select(&self.class.scopes[name]))
          end
        else
        end
      end

      def [](*args)
        if args.size == 1 && args.first.is_a?(Symbol)
          unless self.class.finder.nil?
            return @array.find { |e| self.class.finder.call(e) == args.first }
          end
        else
        end
        @array[*args]
      end

      %i(& + * - | clear collect collect! delete_if drop drop_while each
         each_index keep_if first last map reject reject! reverse reverse!
         reverse_each rotate rotate! sample select select! shift shuffle
         shuffle! slice slice! sort sort! sort_by! take take_while uniq uniq!
         values_at).each do |method|
        define_method method do |*args, &block|
          result = @array.send(method, *args, &block)
          if result == @array
            self
          elsif result.is_a?(Array)
            self.class.new(result)
          else
            result
          end
        end
      end

      def <<(obj)
        return unless self.class.entity?(obj)
        @array << obj
      end

      def []=(*args)
        return unless self.class.entity?(args.last)
        @array.send(:[]=, *args)
      end

      def to_a
        @array
      end

      def to_ary
        @array
      end

      %i(concat replace).each do |method|
        define_method method do |other|
          @array.send(method, self.class.select(other))
          self
        end
      end

      def fill(*args)
        if block_given?
          @array.fill(*args) do |index|
            obj = yield index
            self.class.entity?(obj) ? obj : @array[index]
          end
        else
          return self unless self.class.entity?(args.first)
          @array.fill(*args)
        end
        self
      end

      def insert(index, *other)
        @array.insert(index, self.class.select(other))
        self
      end

      def map!(&block)
        array = @array
        array_class = self.class
        enum = Enumerator.new do |yielder|
          array.replace(array.map do |entity|
            obj = (yielder << entity)
            array_class.entity?(obj) ? obj : nil
          end.compact)
        end
        if block_given?
          enum.each(&block)
          self
        else
          enum
        end
      end

      %i(push unshift).each do |method|
        define_method method do |*args|
          @array.send(method, *self.class.select(args))
          self
        end
      end

      %i(assoc combination compact compact! flatten flatten pack permutation
         product rassoc repeated_combination repeated_permutation transpose
         zip).each do |method|
        define_method method do |*args|
          fail(
            RuntimError,
            "Method #{method} is not allowed in #{self.class.name}"
          )
        end
      end
    end
  end
end
