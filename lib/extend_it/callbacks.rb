require File.join %w(extend_it symbolize)
require File.join %w(extend_it class)

using ExtendIt::Symbolize

module ExtendIt
  module Callbacks
    CALLBACKS = %i(before after around)

    def self.included(base)
      unless base.is_a?(Class)
        fail RuntimeError, 'Can be included in classes only'
      end
      unless (class << base; self end).included_modules.include?(ExtendIt::Class)
        fail RuntimeError, "#{base.name} should extend ExtendIt::Class"
      end
      base.extend(ClassMethods)
    end

    def self.extended(base)
      fail RuntimeError, 'This module can\'t be extended'
    end

    def run_callbacks(*names, arguments: [], original_context: false)
      # sanitize arguments
      arguments = [] if arguments.nil?
      arguments = [arguments] unless arguments.is_a?(Array)

      parents = self.class.parents
      parents_rev = parents.reverse

      names.ensure_symbols.each do |name|
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

    module ClassMethods
      def define_callbacks(*names, callbacks: [:before, :after])
        callbacks = [:before, :after] unless callbacks.is_a?(Array)
        callbacks.select! { |cb| CALLBACKS.include?(cb) }
        names.each do |name|
          name = name.symbolize || next
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
