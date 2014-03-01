require 'spec_helper'

describe AdminIt::ObjectData::Context do
  before do
    object_class.class_eval do
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

  it 'retrieves all fields for ancestors' do
    fields = object_context.fields(scope: :all)
    expect(fields.size).to eq 3
  end

  it 'reads fields' do
    single_object_context.entity = object
    expect(single_object_context.values).to eq r: 'r_value', rw: 'rw_value'
  end
end

describe AdminIt::ObjectData::Field do
end
