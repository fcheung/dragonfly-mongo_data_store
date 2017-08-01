# encoding: utf-8
require 'spec_helper'
require 'dragonfly/mongo_data_store'
require 'dragonfly/spec/data_store_examples'
require 'mongo'

describe Dragonfly::MongoDataStore do

  let(:app) { Dragonfly.app }
  let(:content) { Dragonfly::Content.new(app, "Pernumbucano") }
  let(:new_content) { Dragonfly::Content.new(app) }

  before(:each) do
    @data_store = Dragonfly::MongoDataStore.new :database => 'dragonfly_test', :host => 'localhost'
  end

  describe "configuring the app" do
    it "can be configured with a symbol" do
      app.configure do
        datastore :mongo
      end
      app.datastore.should be_a(Dragonfly::MongoDataStore)
    end
  end

  it_should_behave_like 'data_store'

  describe "connecting to a replica set" do
    it "should initiate a replica set connection if hosts is set" do
      @data_store.hosts = ['1.2.3.4:27017', '1.2.3.4:27017']
      @data_store.connection_opts = {:replica_set => 'testingset'}
      Mongo::Client.should_receive(:new).with(['1.2.3.4:27017', '1.2.3.4:27017'], :database => 'dragonfly_test', :replica_set => 'testingset')
      @data_store.connection
    end
  end

  describe "connecting with a uri" do
    it "should initialize the driver with the uri" do
      @data_store.uri = "mongodb://localhost:27017/some_db"
      @data_store.connection_opts = {:read_retry_interval => 1}
      Mongo::Client.should_receive(:new).with("mongodb://localhost:27017/some_db", :database => 'dragonfly_test', :read_retry_interval => 1)
      @data_store.connection
    end

    it 'uses the db from the uri' do
      @data_store = Dragonfly::MongoDataStore.new uri: "mongodb://localhost:27017/some_db"
      @data_store.db.name.should == 'some_db'
    end
  end


  describe "authenticating" do

    it "should pass credentials to the driver" do
      @data_store.username = 'terry'
      @data_store.password = 'butcher'
      Mongo::Client.should_receive(:new).with(anything, database: 'dragonfly_test', user: 'terry', password: 'butcher')
      @data_store.connection
    end
  end

  describe "sharing already configured stuff" do
    before(:each) do
      @connection = Mongo::Client.new(['localhost:27017'])
    end

    it "should allow sharing the connection" do
      data_store = Dragonfly::MongoDataStore.new :connection => @connection
      @connection.should_receive(:database).and_return(db=double)
      data_store.db.should == db
    end

    it "should allow sharing the db" do
      db = @connection.with(database: 'dragonfly_test_yo').database 
      data_store = Dragonfly::MongoDataStore.new :db => db
      data_store.grid.database.should == db # so wrong
    end
  end

  describe "content type" do
    it "should serve straight from mongo with the correct content type (taken from ext)" do
      content.name = 'text.txt'
      uid = @data_store.write(content)
      response = @data_store.grid.find_one(_id: BSON::ObjectId(uid))
      response.info.content_type.should == 'text/plain'
      response.data.should == content.data
    end
  end

  describe "already stored stuff" do
    it "still works" do
      file = Mongo::Grid::File.new("DOOBS",:metadata => {'some' => 'meta'})
      uid = @data_store.grid.insert_one(file)
      new_content.update(*@data_store.read(uid))
      new_content.data.should == "DOOBS"
      new_content.meta['some'].should == 'meta'
    end

    it "still works when meta was stored as a marshal dumped hash (but stringifies keys)" do
      file = Mongo::Grid::File.new("DOOBS",:metadata => Dragonfly::Serializer.b64_encode(Marshal.dump(:some => 'stuff')))
      uid = @data_store.grid.insert_one(file)      
      c, meta = @data_store.read(uid)
      meta['some'].should == 'stuff'
    end
  end

end

