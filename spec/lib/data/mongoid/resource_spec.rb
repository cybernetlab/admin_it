require 'spec_helper'

if ENV['USE_MONGOID']
  describe AdminIt::MongoidData::Resource do
    before do
      #
      class MongoTestEmbed
        include Mongoid::Document
        field :name, type: String
        embedded_in :mongo_test_parent
      end
      #
      class MongoTestParent
        include Mongoid::Document
        field :name, type: String
        embeds_many :mongo_test_embeds
      end
    end

    after do
      if Object.const_defined?(:MongoTestParent)
        Object.send(:remove_const, :MongoTestParent)
      end
    end

    let(:resource) { AdminIt::Resource.new(:mongo_test, MongoTestParent) }

    it 'provides default fields' do
      expect(
        resource.fields(scope: :all).map(&:field_name)
      ).to match_array %i(id name mongo_test_embeds)
    end

    it 'hides id field' do
      expect(resource.field(:id).visible?).to be_false
    end

    it 'gives right field types' do
      expect(resource.field(:id).type).to eq :integer
      expect(resource.field(:name).type).to eq :string
      expect(resource.field(:mongo_test_embeds).type).to eq :relation
    end

    it 'provides default filters' do
      expect(
        resource.filters.map(&:filter_name)
      ).to match_array %i(name_value)
    end
  end
end
