require 'spec_helper'

if ENV['USE_MONGOID']
  describe AdminIt::MongoidData::Field do
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
  end
end
