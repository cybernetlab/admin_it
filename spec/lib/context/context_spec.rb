require 'spec_helper'

describe AdminIt::Context do
  subject { described_class.create_class.new }

  it { expect(subject.collection?).to be_false }
  it { expect(subject.single?).to be_false }

  it 'sets entity class to Object by default' do
    expect(subject.entity_class).to eq Object
  end

  it 'sets fields to empty array by default' do
    expect(subject.class.fields).to eq []
  end

  it 'extends AdminIt::Object context by default' do
    expect(subject.class.included_modules)
      .to include AdminIt::ObjectData::Context
  end
end

