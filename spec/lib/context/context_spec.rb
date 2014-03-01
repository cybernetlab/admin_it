require 'spec_helper'

describe AdminIt::Context do
  let(:context_class) { described_class.create_class(:test, object_resource) }
  subject { context_class.new }

  # DSL methods
  it { expect(context_class.collection?).to be_false }
  it { expect(context_class.single?).to be_false }

  # instance methods
  it { expect(subject.collection?).to be_false }
  it { expect(subject.single?).to be_false }

  it 'sets entity class to Resource entity class' do
    expect(subject.entity_class).to eq object_resource.entity_class
  end

  it 'sets fields to empty array by default' do
    expect(subject.class.fields).to eq []
  end

  it 'extends AdminIt::Object context by default' do
    expect(subject.class.included_modules)
      .to include AdminIt::ObjectData::Context
  end
end

