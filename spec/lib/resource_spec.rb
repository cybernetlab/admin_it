require 'spec_helper'

describe AdminIt::Resource do
  subject do
    object_class
    described_class.new(:object_class)
  end

  it 'resolves entity_class from name' do
    expect(subject.entity_class).to eq ObjectClass
  end

  it 'makes default display name' do
    expect(subject.display_name).to eq 'Object Classes'
  end

  describe '#initialize' do
  end

  context 'with single context' do
    before { subject.contexts << single_object_context_class }

    xit 'provides hash-like reader for contexts' do
      expect(subject[:single]).to eq single_object_context_class
    end
  end
end
