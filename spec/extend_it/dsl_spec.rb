require 'spec_helper'
require File.join %w(extend_it dsl)

describe ExtendIt::Dsl do
  let :includer_class do
    mod = described_class
    Class.new do
      include mod
      attr_accessor :test, :tests
    end
  end

  let :includer_obj do
    includer_class.new
  end

  let :dsl_class do
    mod = described_class
    Class.new do
      include mod
    end
  end

  describe '#dsl_accessor' do
    it 'creates getter and setter' do
      includer_class.dsl { dsl_accessor :test }
      includer_obj.dsl_eval { self.test 10 }
      expect(includer_obj.test).to eq 10
    end

    it 'creates getter that with argument works as setter' do
      includer_class.dsl { dsl_accessor :test }
      includer_obj.dsl_eval { test(10) }
      expect(includer_obj.test).to eq 10
    end

    it 'creates accessors from array' do
      includer_class.dsl { dsl_accessor :test, ['one', :two], 10 }
      expect(includer_obj.dsl_obj).to respond_to :test
      expect(includer_obj.dsl_obj).to respond_to :one
      expect(includer_obj.dsl_obj).to respond_to :two
    end

    it 'uses default value' do
      includer_class.dsl { dsl_accessor :test, default: 10 }
      expect(includer_obj.dsl_obj.test).to eq 10
    end

    it 'uses setter to set value if it given' do
      includer_class.dsl { dsl_accessor(:test) { 10 } }
      expect(includer_obj.dsl_obj.test).to eq 10
    end

    xit 'evals block in object context with getter if is Dsl' do
      includer_class.dsl { dsl_accessor :test }
      dsl_class.dsl { dsl_accessor :child }
      obj = includer_obj.dsl_obj
      includer_obj.dsl_eval { test(obj) { child 'test' } }
      expect(includer_obj.instance_variable_get(:@child)).to eq 'test'
    end
  end

  describe '#dsl_boolean' do
    it 'creates getter and setter' do
      includer_class.dsl { dsl_boolean :test }
      includer_obj.dsl_obj.test = false
      expect(includer_obj.test).to be_false
    end

    it 'sets values to true by default' do
      includer_class.dsl { dsl_boolean :test }
      expect(includer_obj.dsl_obj.test).to be_true
    end

    it 'creates booleans from array' do
      includer_class.dsl { dsl_boolean :test, ['one', :two], 10 }
      expect(includer_obj.dsl_obj).to respond_to :test
      expect(includer_obj.dsl_obj).to respond_to :one
      expect(includer_obj.dsl_obj).to respond_to :two
    end
  end

  describe '#dsl_block' do
    it 'creates setter and getter' do
      block = proc { :test }
      includer_class.dsl { dsl_block :test }
      includer_obj.dsl_obj.test(&block)
      expect(includer_obj.test).to eq block
    end
  end

  describe '#dsl_use_hash' do
    before do
      includer_class.dsl { dsl_use_hash :tests }
      includer_obj.tests = { one: 1, two: 2, three: 3 }
    end

    it 'reorders hash' do
      includer_obj.dsl_obj.use_tests :two, :three, :one
      expect(includer_obj.tests).to eq(two: 2, three: 3, one: 1)
    end

    it 'recreates hash' do
      includer_obj.dsl_obj.use_tests :two, :three
      expect(includer_obj.tests).to eq(two: 2, three: 3)
    end

    it 'excludes hash' do
      includer_obj.dsl_obj.use_tests :three, :one, :two, except: :one
      expect(includer_obj.tests).to eq(three: 3, two: 2)
    end

    it 'excludes hash with except only option' do
      includer_obj.dsl_obj.use_tests except: :one
      expect(includer_obj.tests).to eq(two: 2, three: 3)
    end
  end

  describe '#dsl_hash_of_objects' do
    it 'creates objects with creator' do
      objects = { one: Object.new, two: Object.new }
      includer_class.dsl do
        dsl_hash_of_objects(:tests) { |name| objects[name] }
      end
      includer_obj.dsl_obj.tests :one, :two
      expect(includer_obj.tests).to eq objects
    end

    it 'creates objects on demand' do
      objects = { one: Object.new }
      demand = Object.new
      includer_class.dsl { dsl_hash_of_objects(:tests) { |_| demand } }
      includer_obj.tests = objects
      includer_obj.dsl_obj.tests :one, :two
      expect(includer_obj.tests).to eq(objects.merge(two: demand))
    end
  end
end
