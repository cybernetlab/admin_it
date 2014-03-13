require 'spec_helper'

describe AdminIt::ResourceDefinition do
  subject { described_class.new(object_resource) }

  it 'delegates methods to fake context' do
    subject.field :name
    expect(
      subject.instance_variable_get(:@fake).find_field(:name)
    ).to_not be_nil
  end

  describe '#default_context' do
    it 'returns first single context name by default' do
      subject.contexts(%i(tiles edit table))
      expect(subject.default_context).to eq :edit
    end

    it 'drops unknown context name' do
      subject.default_context(:test)
      expect(subject.default_context).to eq :show
    end

    it 'sets known context name' do
      subject.default_context(:table)
      expect(subject.default_context).to eq :table
    end
  end

  describe '#icon' do
    it 'has nil icon by default' do
      expect(subject.icon).to be_nil
    end

    it 'sets icon as string' do
      subject.icon :test
      expect(subject.icon).to eq 'test'
    end
  end

  describe '#single' do
    it { expect(subject.single <= AdminIt::SingleContext).to be_true }

    it 'copies fields from fake context' do
      subject.field :name
      expect(subject.single.fields[:name]).to_not be_nil
    end

    it 'yields block in single instance context' do
      expect(subject.single).to receive(:instance_eval)
      subject.single { }
    end
  end

  describe '#collection' do
    it { expect(subject.collection <= AdminIt::CollectionContext).to be_true }

    it 'copies fields from single context' do
      subject.field :name
      expect(subject.collection.find_field(:name)).to_not be_nil
    end

    it 'yields block in collection instance context' do
      expect(subject.collection).to receive(:instance_eval)
      subject.collection { }
    end
  end

  describe '#context' do
    it 'yields block in context instance context' do
      expect(subject.context(:edit)).to receive(:instance_eval)
      subject.context(:edit) { }
    end

    it 'creates context on-demand' do
      subject.context :test, context_class: AdminIt::TilesContext
      expect(subject.contexts.map(&:context_name)).to include :test
      expect(subject.context(:test) <= AdminIt::TilesContext).to be_true
    end

    context 'with some fields' do
      before do
        subject.field :name
        subject.single { field :amount }
        subject.collection { field :size }
      end

      it 'copies fields from single fake context for singles' do
        subject.context(:edit) { field :title }
        expect(subject.context(:edit).fields[:title]).to_not be_nil
        expect(subject.context(:edit).fields[:name]).to_not be_nil
        expect(subject.context(:edit).fields[:amount]).to_not be_nil
        expect(subject.context(:edit).fields[:size]).to be_nil
      end

      it 'copies fields from collection fake context for collections' do
        subject.context(:table) { field :rows }
        expect(subject.context(:table).fields[:rows]).to_not be_nil
        expect(subject.context(:table).fields[:amount]).to be_nil
        expect(subject.context(:table).fields[:name]).to_not be_nil
        expect(subject.context(:table).fields[:size]).to_not be_nil
      end

      it 'copies fields from single fake context for on-demand singles' do
        subject.context :test, context_class: AdminIt::EditContext do
          field :title
        end
        expect(subject.context(:test).fields[:title]).to_not be_nil
        expect(subject.context(:test).fields[:name]).to_not be_nil
        expect(subject.context(:test).fields[:amount]).to_not be_nil
        expect(subject.context(:test).fields[:size]).to be_nil
      end

      it 'copies fields from col fake context for on-demand collections' do
        subject.context :test, context_class: AdminIt::TableContext do
          field :rows
        end
        expect(subject.context(:test).fields[:rows]).to_not be_nil
        expect(subject.context(:test).fields[:name]).to_not be_nil
        expect(subject.context(:test).fields[:amount]).to be_nil
        expect(subject.context(:test).fields[:size]).to_not be_nil
      end
    end
  end

  describe '#contexts' do
    it 'yields block in each context instance context' do
      subject.contexts.each { |c| expect(c).to receive(:instance_eval) }
      subject.contexts { }
    end

    it 'reorders contexts' do
      list = %i(list tiles show table edit new)
      subject.contexts(*list)
      expect(subject.contexts.map(&:context_name)).to eq list
    end

    it 'reduces contexts' do
      subject.contexts(:tiles, :table)
      expect(subject.contexts.size).to eq 2
    end
  end

  describe '#exclude_collection' do
    it 'removes all collection contexts' do
      subject.exclude_collection
      expect(subject.contexts.map(&:context_name))
        .to eq described_class::SINGLE
    end
  end

  describe '#exclude_single' do
    it 'removes all single contexts' do
      subject.exclude_single
      expect(subject.contexts.map(&:context_name))
        .to eq described_class::COLLECTIONS
    end
  end

  describe '#exclude_context' do
    it 'removes contexts' do
      subject.exclude_context(%i(show edit new table))
      expect(subject.contexts.map(&:context_name)).to eq %i(tiles list)
    end
  end
end

describe AdminIt do
  describe '.resource' do
  end
end
