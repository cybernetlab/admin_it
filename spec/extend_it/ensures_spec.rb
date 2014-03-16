require 'spec_helper'
require File.join %w(extend_it ensures)

using ExtendIt::Ensures if ExtendIt.config.use_refines?

describe ExtendIt::Ensures do
  describe '#ensure_symbol' do
    it 'returns self for symbols' do
      expect(:test.ensure_symbol).to eq :test
    end

    it 'returns symbolized string for strings' do
      expect('test'.ensure_symbol).to eq :test
    end

    it 'returns nil for others' do
      expect([].ensure_symbol).to be_nil
    end
  end

  describe '#ensure_symbols' do
    it 'returns flatten array of symbols for array' do
      expect([[:some, 'test'], [:of, 0, nil, 'array']].ensure_symbols)
        .to eq %i(some test of array)
    end

    it 'returns [self] for symbols' do
      expect(:test.ensure_symbols).to eq [:test]
    end

    it 'returns array with single symbolized string for strings' do
      expect('test'.ensure_symbols).to eq [:test]
    end

    it 'returns [] for non-arrays' do
      expect(true.ensure_symbols).to eq []
    end
  end
end
