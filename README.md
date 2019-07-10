# Dragonfly::MongoDataStore

Mongo data store for use with the [Dragonfly](http://github.com/markevans/dragonfly) gem.

## Gemfile

```ruby
gem 'dragonfly-mongo_data_store'
```

## Usage

Configuration, with default options (remember the require)

```ruby
require 'dragonfly/mongo_data_store'

Dragonfly.app.configure do
  # ...

  datastore :mongo

  # ...
end
```

Or with options:

```ruby
datastore :mongo, host: 'my.host', database: 'my_database'
```

### Available options

```ruby
:host              # e.g. 'my.domain'
:hosts             # for replica sets, e.g. ['n1.mydb.net:27017', 'n2.mydb.net:27017']
:connection_opts   # hash that passes through to MongoV1::Connection or MongoV1::ReplSetConnection
:port              # e.g. 27017
:database          # defaults to 'dragonfly'
:username
:password
:connection        # use this if you already have a MongoV1::Connection object
:db                # use this if you already have a MongoV1::DB object
```

