require 'json'
require 'csv'
require File.join %w(extend_it symbolize)

using ExtendIt::Symbolize

module AdminIt
  class CollectionContext < Context
    extend FiltersHolder

    @entities_getter = nil

    class << self
      dsl_block :entities
      dsl_accessor :default_sorting
      dsl_use_hash :filters
    end

    def self.before_configure
      return if resource.nil?
      visible = fields(scope: :visible).map(&:field_name)
      @filters = Hash[
        resource.filters
          .select { |f| f <= FieldFilter }
          .select { |f| visible.include?(f.field.field_name) }
          .map { |f| [f.filter_name, f] }
      ]
    end

    def self.filter(name, filter_class: nil, &block)
      assert_symbol(:name)
      if @filters.key?(name)
        filter = @filters[name] = Class.new(@filters[name]) if block_given?
      else
        filter_class = Filter if filter_class.nil? || !filter_class <= Filter
        filter = @filters[name] = filter_class.create(name, self)
      end
      filter.instance_eval(&block) if block_given?
    end

    def self.entities_getter
      @entities
    end

    def self.collection?
      true
    end

    def self.path
      AdminIt::Engine.routes.url_helpers.send("#{resource.plural}_path")
    end

    def self.sortable_fields(*names)
      names = names.ensure_symbols
      fields.each do |_field|
        _field.sortable = names.include?(_field.field_name)
      end
    end

    attr_accessor :entity
    class_attr_reader :entities_getter, :path

    before_load do |store: {}, params: {}|
      self.sorting = store[:sorting] || self.class.default_sorting
      self.sorting = params[:sorting] if params.key?(:sorting)
      self.filters = store[:filters] || []
      self.filters = params[:filters] if params.key?(:filters)
    end

    after_load do |store: {}, params: {}|
      self.active_filter = params[:active_filter] || store[:active_filter]
    end

    before_save do |params: {}|
      params.merge!(sorting: sorting.join(';'))
      params.merge!(filters: filters.map { |f| f.dump }.join(';'))
      unless active_filter.nil?
        params.merge!(active_filter: active_filter.name.to_s)
      end
    end

    def sorting
      return @sorting unless @sorting.nil?
      self.sorting = self.class.default_sorting
    end

    def sorting=(value)
      value = value.to_s if value.is_a?(Symbol)
      if value.is_a?(Array)
        @sorting = value
      elsif value.is_a?(String) && !value.empty?
        @sorting = [] unless /\W[+\-]\w/ =~ value
        @sorting ||= []
        sortable = self.class.fields(scope: :sortable).map(&:field_name)
        value.split(/[;,|]/).each do |sort|
          sort.strip!
          if sort[0] == '-'
            sort = sort[1..-1] + ':'
            @sorting.delete_if { |s| s.index(sort) == 0 }
          else
            sort = sort[1..-1] if sort[0] == '+'
            sort, order = sort.split(':')
            order = 'asc' if order != 'desc'
            sort = sort.to_sym
            @sorting << "#{sort}:#{order}" if sortable.include?(sort)
          end
        end
      else
        @sorting = []
      end
    end

    def all_filters
      self.class.filters
    end

    def filters
      (@filters ||= {}).values
    end

    def filters=(value)
      if value.is_a?(Array)
        @filters = Hash[
          value.select { |f| f.is_a?(Filter) }.map { |f| [f.name, f] }
        ]
      elsif value.is_a?(Hash)
        self.filters = value.values
      elsif value.is_a?(String)
        @filters ||= {}
        value.strip!
        @filters = {} if value.empty?
        Filter.apply(value, @filters, self.class.filters)
      else
        @filters = {}
      end
    end

    def active_filter
      @active_filter ||= filters.empty? ? nil : filters.first
    end

    def active_filter=(value)
      if value.nil?
        active_filter
      elsif value.is_a?(Class) && value <= Filter
        @active_filter = value
      elsif value.is_a?(String)
        value = value.to_sym
        @active_filter = filters.find { |f| f.name == value }
      end
    end

    def sortable_fields
      @sortable_fields ||= fields(scope: :sortable)
    end

    def sortable
      @sortable ||= sortable_fields.map(&:name)
    end

    def load_context
      collection =
        if entities_getter.nil?
          if controller.respond_to?("#{resource.name}_entities")
            controller.send("#{resource.name}_entities", name)
          elsif controller.respond_to?(:entities)
            controller.entities(entity_class, name)
          else
            load_entities
          end
        else
          entities_getter.call
        end
      filters.each do |filter|
        collection = filter.apply(collection)
      end
      self.entities = collection
    end

    def entities=(value)
      @entities = value
    end

    def entities
      self.entity = nil
      collection = self
      @enumerator ||= Enumerator.new do |yielder|
        @entities.each do |v|
          collection.entity = v
          yielder << v
        end
        collection.entity = nil
      end
    end

    def count
      return @count unless @count.nil?
      # apply filters and limits first
      entities if @enumerator.nil?
      # if @count is not setted yet - calculate it
      @count = entities.count
    end

    protected

    def load_entities
      []
    end
  end

  class ListContext < CollectionContext
    def self.path
      AdminIt::Engine.routes.url_helpers.send("list_#{resource.plural}_path")
    end

    class << self
      protected

      def default_icon
        'bars'
      end
    end
  end
end
