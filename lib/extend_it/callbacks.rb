require File.join %w(extend_it base)

module ExtendIt
  #
  module Callbacks
    using EnsureIt if EnsureIt.refined?

    CALLBACKS = %i(before after around)

    def self.included(base)
      fail 'Can be included in classes only' unless base.is_a?(Class)
      unless (class << base; self end).included_modules.include?(Base)
        fail "#{base.name} should extend ExtendIt::Base"
      end
      base.extend(ClassMethods)
    end

    def self.extended(base)
      fail 'This module can\'t be extended'
    end

    def run_callbacks(*names, arguments: [], original_context: false)
      # sanitize arguments
      arguments = arguments.ensure_array(make: true)

      parents = self.class.parents
      parents_rev = parents.reverse

      names = names.ensure_array(:flatten, :ensure_symbol, :compact, :uniq)
      names.each do |name|
        around = []
        around_name = "@around_#{name}".to_sym
        var_name = "@before_#{name}".to_sym
        parents_rev.each do |p|
          if p.instance_variable_defined?(around_name)
            arr = p.instance_variable_get(around_name)
            arr.each do |b|
              if original_context == true
                b.call(*arguments)
              else
                instance_exec(*arguments, &b)
              end
            end
            around.concat(arr)
          end
          if p.instance_variable_defined?(var_name)
            p.instance_variable_get(var_name).each do |b|
              if original_context == true
                b.call(*arguments)
              else
                instance_exec(*arguments, &b)
              end
            end
          end
        end
        yield if block_given?
        around.reverse.each do |b|
          if original_context == true
            b.call(*arguments)
          else
            instance_exec(*arguments, &b)
          end
        end
        var_name = "@after_#{name}".to_sym
        parents.each do |p|
          if p.instance_variable_defined?(var_name)
            p.instance_variable_get(var_name).each do |b|
              if original_context == true
                b.call(*arguments)
              else
                instance_exec(*arguments, &b)
              end
            end
          end
        end
      end
    end

    #
    module ClassMethods
      def define_callbacks(*names, callbacks: [:before, :after])
        callbacks = [:before, :after] unless callbacks.is_a?(Array)
        callbacks = callbacks.ensure_array(values: CALLBACKS)
        names = names.ensure_array(:flatten, :ensure_symbol, :compact, :uniq)
        names.each do |name|
          callbacks.each do |cb|
            cb_name = "#{cb}_#{name}".to_sym
            var_name = "@#{cb_name}".to_sym
            define_singleton_method cb_name do |&block|
              return if block.nil?
              arr =
                if instance_variable_defined?(var_name)
                  instance_variable_get(var_name)
                else
                  instance_variable_set(var_name, [])
                end
              arr << block
            end
          end
        end
      end
    end
  end
end
