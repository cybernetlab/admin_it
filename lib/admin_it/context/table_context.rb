require File.join %w(extend_it dsl)

module AdminIt
  class TableContext < CollectionContext
    class << self
      dsl_accessor :page_size, default: 10 do |value|
        value.is_a?(Fixnum) && value > 0 ? value : 10
      end

      dsl_boolean :actions

      dsl_block :row

      protected

      def default_icon
        'table'
      end
    end

    def self.path
      AdminIt::Engine.routes
        .url_helpers.send("table_#{resource.plural}_path")
    end

    class_attr_reader :page_size, :actions?

    after_load do |store: {}, params: {}|
      self.page = params[:page] || store[:page]
    end

    before_save do |params: {}|
      params.merge!(page: page)
    end

    def pages
      @pages ||= (count.to_f / page_size).ceil
    end

    def page
      @page ||= 1
    end

    def page=(value)
      if value.is_a?(String)
        value = case value.downcase
        when 'next' then page + 1
        when 'prev', 'previous' then page - 1
        when 'first' then 1
        when 'last' then pages
        else value.to_i
        end
      end
      if value.is_a?(Fixnum) && value > 0 && value <= pages
        # reset entities enumerator if page changed
        @enumerator = nil if !@enumerator.nil? && value != @page
        @page = value
      end
      @page ||= 1
    end

    def headers
      Hash[fields.map { |f| [f.name, f.display_name] }]
    end
  end
end
