#
# Helpers for WrapIt testing
#
# @author Alexey Ovchinnikov <alexiss@cybernetlab.ru>
#
module WrappedExampleGroup
=begin
  def self.included(base)
    base.instance_eval do
      metadata[:type] = :wrap_it

      after do
        @successor = nil
        @wrapper = nil
      end

      let(:template_wrapper) { Object.new }

      let(:successor_class) { Class.new described_class }

      let(:wrapper_class) do
        mod = described_class
        if BASE_MODULES.include? mod
          Class.new(WrapIt::Base)
        else
          Class.new(WrapIt::Base) { include mod }
        end
      end
    end
  end

  def successor(*args, &block)
    templ = respond_to?(:template) ? template : template_wrapper
    @successor ||= successor_class.new(templ, *args, &block)
  end

  def wrapper(*args, &block)
    templ = respond_to?(:template) ? template : template_wrapper
    @wrapper ||= wrapper_class.new(templ, *args, &block)
  end

  RSpec.configure do |config|
    config.include(
      self,
      type: :wrapped,
      example_group: { file_path: /spec\/(wrapped|integration)/ }
    )
  end
=end
end
