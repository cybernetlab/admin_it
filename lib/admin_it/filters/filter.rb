require 'date'
require 'json'
require File.join %w(extend_it base)
require File.join %w(extend_it dsl)
require File.join %w(extend_it callbacks)

module AdminIt
  class Filter
    extend ExtendIt::Base
    extend ExtendIt::Dsl
    extend DataBehavior
    extend DisplayableName
    include ExtendIt::Callbacks

    REGEXP = /
      (?<=\A|[,;|])\s*
      (?<full>
        (?<action>[!+\-])?
        (?<name>[a-zA-Z_][a-zA-Z0-9_]*)
        (?:\((?<params>[^)]*)\))?
      )
      \s*(?=[,;|]|\z)
    /x

    ARGUMENT_REGEXP = /
      (?<=\A|[,;|])\s*
      (?:
        (?:(?<action>[+\-])|(?:(?<option>[a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*))?
        (?<token>
          (?:'(?:[^\\']|\\.)*')|
          (?:"(?:[^\\"]|\\.)*")|
          (?:[^,;|\s]+)
        )
      )
      \s*(?=[,;|]|\z)
    /x

    define_callbacks :initialize, :save, :load

    class << self
      attr_reader :filter_name, :resource

      protected

      def create_class(name, _resource)
        name = name.ensure_symbol || fail(
          ArgumentError,
          '`name` argument for `Filter::create_class` should be a Symbol' \
          ' or a String'
        )
        base = self
        Class.new(base) do
          @filter_name, @resource = name, _resource
          @entity_class = @resource.entity_class
          import_data_module(base)
        end
      end

      def default_display_name
        filter_name
      end
    end

    def self.create(name, _resource)
      create_class(name, _resource)
    end

    def self.load(str, filter_classes)
      m = REGEXP.match(str)
      return nil if m.nil? || m[:action] == '-'
      name = m[:name].to_sym
      filter_class = filter_classes.find { |f| f.filter_name == name }
      return nil if filter_class.nil?
      filter = filter_class.new
      filter.load(m[:params])
      filter
    end

    def self.apply(str, filters, filter_classes)
      list = str.scan(Filter::REGEXP)
      filters.clear if list.all? { |_, act, _, _| act.nil? || act.empty? }
      list.each do |full, action, name, params|
        name = name.to_sym
        if action == '-'
          filters.delete(name)
        elsif action == '!'
          filters[name].load(params) if filters.key?(name)
        else
          filters[name] = Filter.load(full, filter_classes)
        end
      end
    end

    class_attr_reader :display_name

    def initialize
      run_callbacks :initialize
    end

    def name
      @name ||= self.class.filter_name
    end

    def dump
      args = []
      opts = {}
      result = ''
      run_callbacks :save, arguments: { arguments: args, options: opts } do
        result = "#{name}"
        unless args.empty? && opts.empty?
          args.concat(opts.map { |k, v| "#{k}:#{v}" })
          result << "(#{args.join(',')})"
        end
      end
      result
    end

    def load(str)
      return if str.nil?
      args = parse_arguments(str)
      unless args.empty?
        opts = args.extract_options!
        run_callbacks :load, arguments: { arguments: args, options: opts }
      end
    end

    def apply(collection)
      collection
    end

    protected

    TRUE_VALUES = %i(true yes)
    FALSE_VALUES = %i(false no)
    NULL_VALUES = %i(nil null)
    OCT_REGEXP = /\A0[0-7]+\z/
    BIN_REGEXP = /\A0[bB][01]+\z/
    HEX_REGEXP = /\A0[xX]\h+\z/
    INT_REGEXP = /\A[+\-]?\d+\z/
    FLOAT_REGEXP = /\A
      [+\-]?
      (?:\d*\.\d+(?:[eE][+\-]?\d+)?)|
      (?:\d+(?:\.\d*)?[eE][+\-]?\d+)
    \z/x
    DATE = %q{[0-3]?[0-9][\/.\-][0-3]?[0-9][\/.\-](?:[0-9]{2})?[0-9]{2}}
    TIME = %q{[0-2]?[0-9][.:\-][0-5]?[0-9]}
    DATE_REGEXP = /\A#{DATE}\z/
    TIME_REGEXP = /\A#{TIME}\z/
    DATETIME_REGEXP = /\A#{DATE}(?:\s+|[\/.\-])#{TIME}\z/

    def param_action(str)
      case str
      when '+' then :add
      when '-' then :remove
      else nil
      end
    end

    def parse_arguments(str)
      opts = {}
      args = []
      parent = self.class.parents.find do |p|
        p.const_defined?(:ARGUMENT_REGEXP)
      end
      unless parent.nil?
        str.scan(parent.const_get(:ARGUMENT_REGEXP)) do |a, o, v|
          if o.nil? || o.empty?
            action = param_action(a)
            action.nil? ? args << v : (opts[action] ||= []) << v
          else
            opts[o.to_sym] = v
          end
        end
      end
      args << opts unless opts.empty?
      args
    end

    def parse_argument(arg)
      return arg unless arg.is_a?(String)
      arg.strip!
      sym = arg.downcase.to_sym
      return nil if NULL_VALUES.include?(sym)
      return true if TRUE_VALUES.include?(sym)
      return false if FALSE_VALUES.include?(sym)
      if (arg[0] == '\'' || arg[0] == '"') && arg[0] == arg[-1]
        return arg[1..-2]
      end
      case arg
      when OCT_REGEXP then arg.to_i(8)
      when BIN_REGEXP then arg.to_i(2)
      when HEX_REGEXP then arg.to_i(16)
      when INT_REGEXP then arg.to_i(10)
      when FLOAT_REGEXP then arg.to_f
      when DATE_REGEXP then Date.parse(arg)
      when TIME_REGEXP then Time.parse(arg)
      when DATETIME_REGEXP then DateTime.parse(arg)
      else JSON.parse(arg)
      end
    end

    def create_argument(arg)
      case arg
      when String then "\"#{arg.gsub('"', '\\"')}\""
      else arg.to_s
      end
    end
  end

  module FiltersHolder
    extend ExtendIt::DslModule

    dsl do
      dsl_hash_of_objects :filters, single: :filter do |name, **opts|
        filter_class = opts[:class] || opts[:filter_class] || Filter
        unless filter_class.is_a?(Class) && filter_class <= Filter
          fail(
            ArgumentError,
            'filter class should be AdminIt::Filter descendant'
          )
        end
        filter_class.create(name, entity_class)
      end
    end

    def filters(scope: :all)
      case scope
      when nil, :all then @filters.values
      when :value then @filters.values.select { |f| f <= ValueFilter }
      else @filters.values
      end
    end

    def filter(name)
      @filters[name.ensure_symbol]
    end
  end
end
