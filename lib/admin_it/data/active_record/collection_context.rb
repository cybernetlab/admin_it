module AdminIt
  module ActiveRecordData
    #
    module CollectionContext
      def entities=(value)
        super(value)
        @count = @entities.nil? ? 0 : @entities.count
      end

      protected

      def load_entities
        collection =
          if AdminIt::Env.pundit?
            controller.policy_scope(entity_class)
          else
            entity_class.all
          end
        if child?
          collection = collection.where(parent.resource.name => parent.entity)
        end
        sort = {}
        sorting.each do |_sort|
          name, order = _sort.split(':')
          sort[name.to_sym] = order.to_sym
        end
        unless collection.nil? || sort.empty?
          collection = collection.order(sort)
        end
        collection
      end
    end

    #
    module TableContext
      def entities
        if @entities.count > page_size
          # limit collection to current page
          @entities = @entities
            .offset(page_size * (page - 1))
            .limit(page_size)
        end
        super
      end
    end
  end
end
