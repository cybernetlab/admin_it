require 'spec_helper'

describe AdminIt::CollectionContext do
  let(:context_class) { described_class.create(:test, object_resource) }
=begin
  subject { context_class.new(nil) }

  # class DSL methods
  it { expect(context_class.collection?).to be_true }
  it { expect(context_class.single?).to be_false }

  # instance methods
  it { expect(subject.collection?).to be_true }
  it { expect(subject.single?).to be_false }

  it 'has entities setter' do
    arr = [object_class.new, object_class.new]
    subject.entities = arr
    expect(subject.entities).to be_kind_of Enumerator
  end
=end
end
