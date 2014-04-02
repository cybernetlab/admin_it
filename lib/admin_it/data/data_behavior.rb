module AdminIt
  #
  module DataBehavior
    private

    def import_data_module(base)
      @data_module = AdminIt.data_module(@entity_class)
      return unless @data_module.is_a?(Module)
      parents.reverse.each do |mod|
        next if mod.name.nil?
        begin
          import_module = @data_module.const_get(mod.name.split('::').last)
          include(import_module) if import_module.is_a?(Module)
        rescue NameError
          nil
        end
      end
    end
  end
end
