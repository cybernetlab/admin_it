require 'spec_helper'

describe AdminIt::SingleContext do
  subject { described_class.create_class.new }

  it { expect(subject.collection?).to be_false }
  it { expect(subject.single?).to be_true }

  it 'sets mode to :new for nil' do
    subject.entity = nil
    expect(subject.entity).to be_kind_of Hash
  end

  it 'sets mode to :edit for Object' do
    subject.entity = Object.new
    expect(subject.entity).to be_kind_of Hash
  end
end
