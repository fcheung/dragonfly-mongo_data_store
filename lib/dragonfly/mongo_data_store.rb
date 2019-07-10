require 'mongo'
require 'dragonfly'

Dragonfly::App.register_datastore(:mongo){ Dragonfly::MongoDataStore }

module Dragonfly
  class MongoDataStore

    include Serializer

    def initialize(opts={})
      @host            = opts[:host]
      @hosts           = opts[:hosts]
      @uri             = opts[:uri]
      @connection_opts = opts[:connection_opts] || {}
      @port            = opts[:port]
      @database        = opts[:database] || (@uri ? nil : 'dragonfly')
      @user            = opts[:user] || opts[:username] #username is the legacy one
      @password        = opts[:password]
      @connection      = opts[:connection]
      @db              = opts[:db]
    end

    attr_accessor :host, :hosts, :connection_opts, :port, :user, :password, :uri
    alias_method :username, :user
    alias_method :username=, :user=

    def write(content, opts={})
      content.file do |f|
        mongo_id = grid.upload_from_stream(nil, f, :content_type => content.mime_type, :metadata => content.meta)
        mongo_id.to_s
      end
    end

    def read(uid)
      result = nil
      grid.open_download_stream(bson_id(uid)) do |stream|
        body = stream.read
        meta = extract_meta(stream.file_info)
        result = [body, meta]
      end
      result 
    rescue Mongo::Error::FileNotFound, BSON::ObjectId::Invalid => e
      nil
    end

    def destroy(uid)
      grid.delete(bson_id(uid))
    rescue Mongo::Error::FileNotFound, BSON::ObjectId::Invalid => e
      Dragonfly.warn("#{self.class.name} destroy error: #{e}")
    end

    def database
      connection.database
    end

    def database= name
      @connection = connection.use(database: name)
    end

    def connection
      @connection ||= if hosts
        Mongo::Client.new(hosts, connection_opts)
      elsif uri
        Mongo::Client.new(uri, connection_opts)
      else
        Mongo::Client.new(["#{host}:#{port}"], connection_opts)
      end
    end

    def db
      @db ||= connection.database
    end

    def grid
      @grid ||= db.fs
    end

    private


    def connection_opts
      @connection_opts.merge(password: password, 
                             database: @database,
                                 user: username).
                       reject {|_, value| value.nil?}
    end

    def bson_id(uid)
      BSON::ObjectId.from_string(uid)
    end

    def extract_meta(file_info)
      meta = file_info.metadata
      meta = Utils.stringify_keys(json_b64_decode(meta)) if meta.is_a?(String) # Deprecated encoded meta
      meta.merge!('stored_at' => file_info.upload_date)
      meta
    end

  end
end

