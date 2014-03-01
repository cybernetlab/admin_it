module AdminIt
  module Utils
    def self.assert_symbol_arg!(arg, name = nil)
      assert_symbol_arg(arg) do
        _caller = caller_locations(3, 1).first
        name = "#{name} " unless name.nil?
        fail(
          ArgumentError,
          "Argument #{name}for #{_caller.label} should be a String or Symbol",
          caller[3..-1]
        )
      end
    end

    def self.assert_symbol_arg(arg)
      return arg if arg.is_a?(Symbol)
      return arg.to_sym if arg.is_a?(String)
      yield arg if block_given?
    end
  end
end
