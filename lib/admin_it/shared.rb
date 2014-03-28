require File.join %w(extend_it dsl)

module AdminIt
  module Renderable
    extend ExtendIt::DslModule

    dsl { dsl_block :render }

    def render(entity, instance = nil, &block)
      return if @render.nil?
      # method used as event emmiter, call block in instance or caller
      # context if it present
      if instance.nil?
        @render.call(entity)
      else
        instance.instance_exec(entity, &@render)
      end
    end
  end

  module Iconed
    extend ExtendIt::DslModule

    dsl do
      dsl_accessor :icon
    end

    def icon=(value)
      @icon = value.nil? ? default_icon : value.to_s
    end

    def icon
      @icon ||= default_icon
    end

    protected

    def default_icon
      ''
    end
  end

  module DisplayableName
    extend ExtendIt::DslModule

    dsl do
      dsl_accessor :display_name
    end

    def display_name=(value)
      @display_name = value.nil? ? default_display_name : value.to_s
    end

    def display_name
      @display_name ||= default_display_name
    end

    protected

    def default_display_name
      ''
    end
  end

  module Defaults
    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.extended(base)
      base.extend(ClassMethods)
    end

    class Definer
      def method_missing(method_name, *args, &block)
        unless /\Adefault_/ =~ method_name
          method_name = "default_#{method_name}".to_sym
        end
        @caller_class.class_eval do
          define_method(method_name, &block)
          protected method_name
        end
      end

      def initialize(caller_class)
        @caller_class = caller_class
      end
    end

    module ClassMethods
      def defaults(&block)
        return unless block_given?
        Definer.new(self).instance_eval(&block)
      end
    end
  end
end
