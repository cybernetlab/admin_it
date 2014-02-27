require 'spec_helper'

describe AdminIt::CollectionContext do
  subject { described_class.create_class.new }

  it { expect(subject.collection?).to be_true }
  it { expect(subject.single?).to be_false }

  it 'has entities setter, that sets mode to :collection' do
    arr = [Object.new, Object.new]
    subject.entities = arr
    expect(subject.entities).to be_kind_of Enumerator
  end
end
