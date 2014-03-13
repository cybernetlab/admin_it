require File.join %w(extend_it symbolize)

using ExtendIt::Symbolize

module ExtendIt
  module Class
    def self.extended(base)
      base.instance_eval do
        define_singleton_method :parents do
          @parents ||= ancestors.take_while { |a| a != base }.concat([base])
        end
      end
    end

    def call_inherited(method_name, *args, base_first: false, &block)
      arr = parents.select { |parent| parent.methods.include?(method_name) }
      arr.reverse! if base_first == true
      arr.reduce([]) { |a, e| a << e.send(method_name, *args, &block) }
    end

    def inherited_class_reader(*names)
      names.ensure_symbols.each do |name|
        var = "@#{name}"
        define_singleton_method(name) do
          p = parents.find { |parent| parent.instance_variable_defined?(var) }
          p.nil? ? nil : p.instance_variable_get(var)
        end
      end
    end

    def class_attr_reader(*attrs)
      attrs.flatten.uniq.each do |attr_name|
        attr_name = attr_name.to_sym if attr_name.is_a?(String)
        next unless attr_name.is_a?(Symbol)
        next if instance_methods.include?(attr_name)
        var_name = "@#{attr_name}".to_sym
        if methods.include?(attr_name)
          define_method(attr_name) { self.class.send(attr_name) }
        elsif instance_variable_defined?(var_name)
          define_method attr_name do
            self.class.instance_variable_get(var_name)
          end
        end
      end
    end
  end
end
