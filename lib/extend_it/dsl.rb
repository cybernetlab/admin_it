require File.join %w(extend_it ensures)

module ExtendIt
  module Dsl
    using ExtendIt::Ensures if ExtendIt.config.use_refines?

    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval do
        define_method :dsl_obj do
          self.class.dsl.new(self)
        end
      end
    end

    def self.extended(base)
      base.extend(ClassMethods)
      base.define_singleton_method :dsl_obj do
        dsl.new(self)
      end
    end

    def dsl_eval(&block)
      dsl_obj.instance_eval(&block) if block_given?
    end

    module ClassMethods
      def dsl(&block)
        if @dsl.nil?
          parent = superclass.respond_to?(:dsl) ? [superclass.dsl] : []
        end
        @dsl ||= Class.new(*parent) do
          extend DslMethods

          def initialize(receiver)
            if receiver.nil? || receiver.frozen?
              fail(ArgumentError, 'DSL receiver should be non-frozen object')
            end
            @dsl_receiver = receiver
          end

          private

          attr_reader :dsl_receiver

          def dsl_get(var_name, default = nil)
            var_name = var_name.ensure_instance_variable_name || fail(
              ArgumentError, "Wrong `var_name` argument: #{var_name.inspect}"
            )
            if default.nil? && !block_given?
              fail(ArgumentError, '`default` or block should be specified')
            end
            if dsl_receiver.instance_variable_defined?(var_name)
              dsl_receiver.instance_variable_get(var_name)
            else
              default = yield if block_given?
              dsl_receiver.instance_variable_set(var_name, default)
            end
          end

          def dsl_set(var_name, value)
            var_name = var_name.ensure_instance_variable_name || fail(
              ArgumentError, "Wrong `var_name` argument: #{var_name.inspect}"
            )
            setter_name = var_name.ensure_setter_name
            if dsl_receiver.respond_to?(setter_name)
              dsl_receiver.send(setter_name, value)
            else
              dsl_receiver.instance_variable_set(var_name, value)
            end
          end
        end
        @dsl.class_eval(&block) if block_given?
        @dsl
      end
    end

    module DslMethods
      def dsl_accessor(*names, default: nil, variable: nil, &setter)
        names = names.ensure_symbols
        variable = nil if names.size != 1
        variable = variable.ensure_local_name unless variable.nil?
        names.each do |name|
          name = name.ensure_local_name || next
          setter_name = name.ensure_setter_name

          define_method setter_name do |*args|
            obj =
              if setter.nil?
                default || args.first
              else
                dsl_receiver.instance_exec(*args, &setter)
              end
            dsl_set(variable || name, obj)
          end

          define_method name do |*args, &block|
            obj = send(setter_name, *args)
            obj.dsl_eval(&block) if !block.nil? && obj.is_a?(Dsl)
            obj
          end
        end
      end

      def dsl_boolean(*names, default: true, variable: nil)
        default = default == true
        names = names.ensure_symbols
        variable = nil if names.size != 1
        variable = variable.ensure_local_name unless variable.nil?
        names.each do |name|
          name = name.ensure_local_name || next
          setter_name = name.ensure_setter_name

          define_method name do |value = nil|
            send(setter_name, value.nil? ? default : value)
          end

          define_method setter_name do |value = default|
            dsl_set(variable || name, value == true)
          end
        end
      end

      def dsl_block(*names, variable: nil)
        names = names.ensure_symbols
        variable = nil if names.size != 1
        variable = variable.ensure_local_name unless variable.nil?
        names.each do |name|
          name = name.ensure_local_name || next
          define_method name do |&block|
            return if block.nil?
            dsl_set(variable || name, block)
          end
        end
      end

      def dsl_use_hash(hash_name, variable: nil)
        hash_name = hash_name.ensure_local_name || fail(
          ArgumentError,
          '`hash_name` argument for `dsl_use_hash` should be a Symbol ' \
          'or a String'
        )
        variable = variable.ensure_local_name unless variable.nil?

        define_method "use_#{hash_name}" do |*names, except: nil|
          hash = dsl_get(variable || hash_name, {})
#          puts "---< #{names}, except: #{except} #{hash.inspect}"
          keys = hash.keys
          names = Dsl.expand_asterisk(names.ensure_symbols, keys)
#          puts "---> #{names}"
          names = names.empty? ? keys : names & keys
#          puts "---> #{names}"
          names -= except.ensure_symbols
#          puts "---> #{names}"
#          puts ''
          hash.replace(Hash[names.map { |n| [n, hash[n]] }])
        end
      end

      def dsl_hash_of_objects(hash_name, variable: nil, single: nil, &creator)
        unless block_given?
          fail(
            ArgumentError,
            '`dsl_hash_of_objects` requires creator block to be present'
          )
        end
        hash_name = hash_name.ensure_local_name || fail(
          ArgumentError,
          '`hash_name` argument for `dsl_hash_of_objects` should be' \
          ' a Symbol or a String'
        )
        variable = variable.ensure_local_name unless variable.nil?

        unless single.nil?
          single = single.ensure_local_name || fail(
            ArgumentError,
            '`single` option for `dsl_hash_of_objects` should be' \
            ' a Symbol or a String or nil'
          )
          define_method single do |name, **opts, &block|
            name = name.ensure_symbol
            unless name.nil?
              hash = dsl_get(variable || hash_name, {})
              obj = hash[name] ||=
                    dsl_receiver.instance_exec(name, **opts, &creator)
              obj.dsl_eval(&block) if !block.nil? && obj.is_a?(Dsl)
            end
          end
        end

        define_method hash_name do |*names, **opts, &block|
          hash = dsl_get(variable || hash_name, {})
          Dsl.expand_asterisk(names.ensure_symbols, hash.keys).each do |name|
            obj = hash[name] ||=
                  dsl_receiver.instance_exec(name, **opts, &creator)
            obj.dsl_eval(&block) if !block.nil? && obj.is_a?(Dsl)
          end
        end

        dsl_use_hash(hash_name, variable: variable)
      end
    end

    protected

    def self.expand_asterisk(arr, keys)
      return arr unless arr.include?(:*)
      arr.map { |a| a == :* ? keys - arr : a }.flatten
    end
  end

  module DslModule
    def self.incuded(base)
      fail RuntimeError, 'DslModule can be only extended by other modules'
    end

    def self.extended(base)
      unless base.is_a?(Module)
        fail RuntimeError, 'DslModule can be only extended by modules'
      end

      base.define_singleton_method :included do |superbase|
        if @included.is_a?(Array)
          @included.each { |i| superbase.instance_eval(&i) }
        end
        if @dsl.is_a?(Array) && superbase.respond_to?(:dsl)
          @dsl.each { |d| superbase.dsl(&d) }
        end
      end

      base.define_singleton_method :extended do |superbase|
        if @extended.is_a?(Array)
          @extended.each { |e| superbase.instance_eval(&e) }
        end
        if @dsl.is_a?(Array) && superbase.respond_to?(:dsl)
          @dsl.each { |d| superbase.dsl(&d) }
        end
      end
    end

    def included(&block)
      (@included ||= []) << block if block_given?
    end

    def extended(&block)
      (@extended ||= []) << block if block_given?
    end

    def dsl(&block)
      (@dsl ||= []) << block if block_given?
    end
  end
end
