require 'require_all'
require 'elasticsearch'

client = Elasticsearch::Client.new log: true

require 'pp'
pp client.search body: {
  query: {
    query_string: {
      query: '*',
      analyze_wildcard: true,
    }
  },
}
