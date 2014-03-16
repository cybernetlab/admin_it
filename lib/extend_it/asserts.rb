require File.join %w(extend_it caller)
require File.join %w(extend_it ensures)

if ExtendIt.config.use_refines?
  using ExtendIt::Caller
  using ExtendIt::Ensures
end

module ExtendIt
  module Asserts
    private

    if RUBY_VERSION >= '2.1.0'
      def assert_symbol(*names, binding: nil)
        return unless binding ||= caller_binding
        names.each do |name|
          name = name.ensure_symbol || next
          var = binding.local_variable_get(name)
          var = var.ensure_symbol || fail(
            ArgumentError,
            "Argument `#{name}` should be a Symbol or String",
            caller[1..-1]
          )
          binding.local_variable_set(name, var)
        end
      end
    else
      def assert_symbol(*names, binding: nil)
        return unless binding ||= caller_binding
        names.each do |name|
          name = name.ensure_symbol || next
          binding.eval(
            "#{name} = #{name}.ensure_symbol || fail(ArgumentError," \
            " 'Argument `#{name}` should be a Symbol or String')"
          )
        end
      end
    end
  end
end
