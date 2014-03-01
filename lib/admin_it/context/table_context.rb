module AdminIt
  class TableContext < CollectionContext
    @row_block = nil

    class << self
      def copy
        proc do |source|
          if source <= TableContext
            @row_block = source.row
            @page_size = source.page_size
          end
        end
      end

      def row(&block)
        block.nil? ? @row_block : @row_block = block
      end

      def page_size(value = nil)
        value.nil? ? @page_size ||= 10 : @page_size = value
      end

      def actions(value)
        @actions = value == true
      end

      def actions?
        @actions.nil? ? @actions = true : @actions == true
      end

      def path
        AdminIt::Engine.routes
          .url_helpers.send("table_#{resource.plural}_path")
      end

      protected

      def default_icon
        'table'
      end
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
