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
    it 'checks name to be a symbol' do
      object_class
      expect(AdminIt::Utils)
        .to receive(:assert_symbol_arg!)
        .with(:object_class, name: 'name')
        .and_call_original
      described_class.new(:object_class)
    end
  end

  context 'with single context' do
    before { subject.contexts << single_object_context_class }

    it 'provides hash-like reader for contexts' do
      expect(subject[:single]).to eq single_object_context_class
    end

    it 'provides context names' do
      expect(subject.contexts_names).to eq [:single]
    end
  end
end
