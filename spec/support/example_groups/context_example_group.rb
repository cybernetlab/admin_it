#
# Helpers for Context testing
#
# @author Alexey Ovchinnikov <alexiss@cybernetlab.ru>
#
module ContextExampleGroup
  def self.included(base)
    base.instance_eval do
      metadata[:type] = :context

      after do
        if Object.const_defined?(:ObjectClass)
          Object.send(:remove_const, :ObjectClass)
        end
      end

      let(:object_class) { Object.const_set(:ObjectClass, Class.new(Object)) }

      let(:object) { object_class.new }

      let(:object_resource) do
        object_class
        AdminIt::Resource.new(:object_class)
      end

      let(:object_context_class) do
        AdminIt::Context.create_class(:object, object_resource)
      end
      let(:object_context) { object_context_class.new }

      let(:single_object_context_class) do
        AdminIt::SingleContext.create_class(:single, object_resource)
      end
      let(:single_object_context) { single_object_context_class.new }

      let(:collection_object_context_class) do
        AdminIt::CollectionContext.create_class(:collection, object_resource)
      end
      let(:collection_object_context) { collection_object_context_class.new }
    end
  end

  RSpec.configure do |config|
    config.include(
      self,
      type: :context,
      example_group: { file_path: %r(spec/lib) }
    )
  end
end
