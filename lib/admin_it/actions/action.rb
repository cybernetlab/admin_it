#
module AdminIt
  using EnsureIt if EnsureIt.refined?

  #
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
      @layout = value.ensure_symbol(values: LAYOUTS)
    end
  end
end
