require 'spec_helper'

describe ExtendIt::Config do
  before do
    @tmp_use_refines = described_class.instance_variable_get(:@use_refines)
    described_class.instance_variable_set(:@use_refines, nil)
  end

  after do
    described_class.instance_variable_set(:@use_refines, @tmp_use_refines)
  end

  describe '::use_refines' do
    it 'sets to false as default' do
      expect(described_class.use_refines).to be_false
    end

    if RUBY_VERSION >= '2.1.0'
      it 'sets value from argument' do
        described_class.use_refines(true)
        expect(described_class.use_refines).to be_true
      end
    else
      it 'avoids of setting true value' do
        expect {
          described_class.use_refines(true)
        }.to raise_error RuntimeError
      end
    end
  end

  describe '::use_refines=' do
    if RUBY_VERSION >= '2.1.0'
      it 'sets value from argument' do
        described_class.use_refines = true
        expect(described_class.use_refines).to be_true
      end
    else
      it 'avoids of setting true value' do
        expect {
          described_class.use_refines = true
        }.to raise_error RuntimeError
      end
    end
  end

  describe '::use_refines?' do
    it 'sets to false as default' do
      expect(described_class.use_refines?).to be_false
    end
  end
end
