module AdminIt
  class Action
    extend ExtendIt::Base
    include ExtendIt::Dsl
    include Iconed
    include DisplayableName

    dsl do
      dsl_accessor :layout
    end

    attr_reader :layout

    def layout=(value)
      value = value.ensure_symbol
      @layout = value.nil? || LAYOUTS.include?(value) ? value : nil
    end
  end
end
