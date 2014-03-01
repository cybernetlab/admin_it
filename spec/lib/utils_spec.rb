require 'spec_helper'

describe AdminIt::Utils do
  subject { AdminIt::Utils }

  describe '.assert_symbol_arg' do
    it 'just passes throw symbol args' do
      expect(subject.assert_symbol_arg(:test)).to eq :test
    end

    it 'converts string to symbol' do
      expect(subject.assert_symbol_arg('test')).to eq :test
    end

    it 'calls block if it given for non-symbol args' do
      test = false
      subject.assert_symbol_arg(10) { |value| test = value }
      expect(test).to eq 10
    end
  end

  describe '.assert_symbol_arg!' do
    def some_method(name)
      subject.assert_symbol_arg!(10, name)
    end

    it 'calls .assert_symbol_arg' do
      expect(subject).to receive(:assert_symbol_arg).with(:test)
      subject.assert_symbol_arg!(:test, name: 'name')
    end

    it 'raises ArgumentError for wrong args' do
      expect { some_method('arg') }.to raise_error(
        ArgumentError,
        'Argument arg for some_method should be a String or Symbol'
      )
    end
  end
end
