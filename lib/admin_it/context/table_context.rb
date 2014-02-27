module AdminIt
  class TableContext < CollectionContext
    @row_block = nil

    def self.copy
      proc do |source|
        if source <= TableContext
          @row_block = source.row
          @page_size = source.page_size
        end
      end
    end

    def self.row(&block)
      if block.nil?
        @row_block
      else
        @row_block = block
      end
    end

    def self.page_size(value = nil)
      if value.nil?
        @page_size ||= 10
      else
        @page_size = value
      end
    end

    def self.actions(value)
      @actions = value == true
    end

    def self.actions?
      @actions.nil? ? @actions = true : @actions == true
    end

    def self.path
      AdminIt::Engine.routes.url_helpers.send("table_#{resource.plural}_path")
    end

    class_attr_reader :page_size, :actions?

    def load(params)
      self.page = params[:page]
    end

    def save(params = {})
      return unless params.is_a?(Hash)
      params.merge!(
        page: page
      )
      super(params)
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
      Hash[self.class.fields.map { |f| [f.name, f.display_name] }]
    end
  end
end
