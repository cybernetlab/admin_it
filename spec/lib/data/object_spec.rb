require 'spec_helper'

describe AdminIt::ObjectData::Context do
  let(:object_class) do
    Class.new do
      def r; 'r_value'; end
      def rw; @rw_value ||= 'rw_value'; end
      def rw=(value); @rw_value = value; end
      def w=(value); @w_value = value; end
      def bool?; true; end
      def wrong_getter_arity(test); true; end
      def wrong_setter1_arity=(test, me); true; end
      def wrong_setter2_arity=; true; end
    end
  end

  let(:object) { object_class.new }

  let(:context) { AdminIt::Context.create_class(object_class) }

  it 'retrieves all fields for ancestors' do
    fields = context.all_fields
    expect(fields.size).to eq 3
  end

  it 'reads fields' do
    c = AdminIt::SingleContext.create_class(object_class).new
    c.entity = object
    expect(c.entity).to eq r: 'r_value', rw: 'rw_value'
  end
end

describe AdminIt::ObjectData::Field do
end
