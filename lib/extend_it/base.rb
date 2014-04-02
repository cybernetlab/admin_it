module ExtendIt
  #
  module Base
    using EnsureIt if ENSURE_IT_REFINED

    def self.extended(base)
      base.instance_eval do
        define_singleton_method :parents do
          @parents ||= ancestors.take_while { |a| a != base }.concat([base])
        end
      end
    end

    def metaclass(&block)
      if @metaclass.nil?
        @metaclass = (class << self; self end)
        @metaclass.extend(Base)
      end
      @metaclass.class_eval(&block) if block_given?
      @metaclass
    end

    def attr_checker(*names)
      names = names.ensure_array(:flatten, :ensure_symbol, :compact, :uniq)
      names.each do |name|
        define_method "#{name}?" do
          instance_variable_get("@#{name}") == true
        end
      end
    end

    def call_inherited(method_name, *args, base_first: false, &block)
      arr = parents.select { |parent| parent.methods.include?(method_name) }
      arr.reverse! if base_first == true
      arr.reduce([]) { |a, e| a << e.send(method_name, *args, &block) }
    end

    def inherited_class_reader(*names)
      names = names.ensure_array(:flatten, :ensure_symbol, :compact, :uniq)
      names.each do |name|
        var = "@#{name}"
        define_singleton_method(name) do
          p = parents.find { |parent| parent.instance_variable_defined?(var) }
          p.nil? ? nil : p.instance_variable_get(var)
        end
      end
    end

    def class_attr_reader(*attrs)
      attrs.ensure_array(:flatten).each do |attr_name|
        attr_name.ensure_symbol(name_of: :local) || next
        next if instance_methods.include?(attr_name)
        var_name = attr_name.ensure_symbol(name_of: :instance_variable)
        if methods.include?(attr_name)
          define_method(attr_name) { self.class.send(attr_name) }
        else
          define_method attr_name do
            p = self.class.parents.find do |parent|
              parent.instance_variable_defined?(var_name)
            end
            p.nil? ? nil : p.instance_variable_get(var_name)
          end
        end
      end
    end
  end
end
