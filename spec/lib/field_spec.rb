require 'spec_helper'

describe AdminIt::Field, type: :context do
  subject { described_class.new(:name, object_class) }

  it 'has name reader' do
    expect(subject.name).to eq :name
  end

  it 'converts name to symbol' do
    expect(described_class.new('test', object_class).name).to eq :test
  end

  it 'has :unknown type by default' do
    expect(subject.type).to eq :unknown
  end

  it 'has DSL type setter' do
    subject.type :string
    expect(subject.type).to eq :string
  end

  it 'rejects reads of write-only fields' do
    f = described_class.new(:name, object_class, readable: false)
    expect { f.read(Object.new) }.to raise_error AdminIt::FieldReadError
  end

  it 'rejects writes to read-only fields' do
    f = described_class.new(:name, object_class, writable: false)
    expect { f.write(Object.new, 1) }.to raise_error AdminIt::FieldWriteError
  end

  it 'calls DSL defined reader for read value' do
    subject.read { |obj| 10 }
    expect(subject.read(Object.new)).to eq 10
  end

  it 'calls DSL defined writer for write value' do
    subject.write { |obj, value| obj[:test] = value }
    expect(subject.write({}, 10)).to eq test: 10
  end

  it 'doesn\'t implements value reading' do
    expect { subject.send(:read_value, Object.new) }
      .to raise_error NotImplementedError
  end

  it 'doesn\'t implements value writing' do
    expect { subject.send(:write_value, Object.new, 'test') }
      .to raise_error NotImplementedError
  end

  it 'has #hide' do
    subject.hide
    expect(subject.visible?).to be_false
  end

  it 'has #show' do
    subject.show
    expect(subject.visible?).to be_true
  end
end
