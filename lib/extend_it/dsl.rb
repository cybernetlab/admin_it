require File.join %w(extend_it asserts)
require File.join %w(extend_it symbolize)

using ExtendIt::Symbolize

module ExtendIt
  module Dsl
    include Asserts

    def dsl_accessor(*names, default: nil, &setter)
      names.flatten.uniq.each do |name|
        name = name.symbolize || next
        var_name = "@#{name}".to_sym
        setter_name = "#{name}=".to_sym
        define_method setter_name do |*args|
          obj =
            if setter.nil?
              default || args.first
            else
              instance_exec(*args, &setter)
            end
          instance_variable_set(var_name, obj)
        end
        define_method name do |*args, &block|
          if args.empty? && block.nil?
            if instance_variable_defined?(var_name)
              instance_variable_get(var_name)
            else
              obj = setter.nil? ? default : instance_exec(&setter)
              instance_variable_set(var_name, obj)
            end
          else
            obj = send(setter_name, *args)
            obj.instance_eval(&block) unless obj.nil? || block.nil?
            obj
          end
        end
      end
    end

    def dsl_boolean(*names, default: true)
      default = default == true
      names.flatten.uniq.each do |name|
        name = name.symbolize || next
        var_name = "@#{name}".to_sym
        define_method "#{name}=" do |value = default|
          instance_variable_set(var_name, value == true)
        end
        define_method "#{name}?" do
          if instance_variable_defined?(var_name)
            instance_variable_get(var_name) == true
          else
            instance_variable_set(var_name, default)
          end
        end
      end
    end

    def dsl_block(*names)
      names.flatten.uniq.each do |name|
        var_name = "@#{name}".to_sym
        define_method name do |*args, &block|
          if block.nil?
            if instance_variable_defined?(var_name)
              instance_variable_get(var_name)
#              instance_exec(*args, &b) unless b.nil?
#            else
#              nil
            end
          else
            instance_variable_set(var_name, block)
          end
        end
      end
    end

    def dsl_use_hash(hash_name)
      assert_symbol(:hash_name, binding: binding)
      define_method "use_#{hash_name}" do |*names, except: nil|
        hash = instance_variable_get("@#{hash_name}")
        if names.empty?
          names = hash.keys
        else
          names = names.ensure_symbols & hash.keys
        end
        except = [except] if !except.nil? && !except.is_a?(Array)
        if except.is_a?(Array)
          names -= except.ensure_symbols
        end
        hash.delete_if { |k, v| !names.include?(k) }
      end
    end
  end
end
