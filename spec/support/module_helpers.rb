#
module ModuleHelpers
  def self.included(base)
    base.class_eval do
      let :includer_class do
        mod = described_class
        Class.new { include mod }
      end

      let(:includer_obj) { includer_class.new }

      let :extender_class do
        mod = described_class
        Class.new { extend mod }
      end

      let(:extender_obj) { extender_class.new }
    end
  end
end
