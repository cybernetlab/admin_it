require 'spec_helper'

describe AdminIt::ResourceDefinition do
  subject { described_class.new(Object) }

  it 'creates empty context list' do
    expect(subject.contexts)
      .to eq new: nil, edit: nil, show: nil, table: nil, tiles: nil, list: nil
  end

  it 'delegates methods to fake context' do
    subject.field :name
    expect(subject.fake_context.find_field(:name)).to_not be_nil
  end

  it 'copies fields from fake context' do
    subject.field :name
    subject.context(:edit) { field :title }
    expect(subject.fake_context.find_field(:name)).to_not be_nil
    expect(subject.fake_context.find_field(:title)).to_not be_nil
  end
end

describe AdminIt do
  describe '.resource' do
  end
end
