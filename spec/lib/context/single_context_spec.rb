require 'spec_helper'

describe AdminIt::SingleContext do
  let(:context_class) { described_class.create_class(:test, object_resource) }

  describe 'DSL methods' do
    subject { context_class }

    it { expect(subject.collection?).to be_false }
    it { expect(subject.single?).to be_true }
  end

  describe 'instance methods' do
    subject { context_class.new }

    it 'sets empty emtity for nil values' do
      subject.entity = nil
      expect(subject.values).to be_kind_of Hash
    end

    it 'sets entity Object' do
      subject.entity = Object.new
      expect(subject.values).to be_kind_of Hash
    end
  end
end
