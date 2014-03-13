require 'date'
require 'json'
require File.join %w(extend_it class)
require File.join %w(extend_it dsl)
require File.join %w(extend_it callbacks)
require File.join %w(extend_it asserts)
require File.join %w(extend_it symbolize)

using ExtendIt::Symbolize

module AdminIt
  class Filter
    extend ExtendIt::Class
    extend DataBehavior
    include ExtendIt::Callbacks
    extend ExtendIt::Asserts

    REGEXP = /\A(?<name>[a-zA-Z_][a-zA-Z0-9_]*)(?:\((?<params>[^)]*)\))?\z/

    define_callbacks :save

    class << self
      extend ExtendIt::Dsl

      attr_reader :filter_name, :resource

      dsl_accessor :display_name do |value = nil|
        value.nil? ? default_display_name : value.to_s
      end

      protected

      def create_class(name, _resource)
        assert_symbol(:name, binding: binding)
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

    def self.load(str, filters)
      m = REGEXP.match(str)
      return nil if m.nil?
      name = m[:name].to_sym
      filter_class = filters.find { |f| f.filter_name == name }
      return nil if filter_class.nil?
      opts = {}
      args = m[:params].nil? ? [] : m[:params].split(',').map do |param|
        param.strip!
        arr = param.split(':')
        if arr.size > 1
          opts[arr[0].strip.to_sym] = arr[1].strip
          nil
        else
          arr[0]
        end
      end
      args << opts unless opts.empty?
      filter_class.new(*args.compact)
    end

    class_attr_reader :display_name

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

    def change(str)
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
end
