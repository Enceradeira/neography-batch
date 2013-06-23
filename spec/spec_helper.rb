require_relative '../lib/neography-batch'

RSpec.configure do |config|
  config.before(:each) do
    neo = Neography::Rest.new
    neo.batch(
        [:execute_query, "START n = node(*) MATCH n-[r]-() WHERE ID(n) > 0 DELETE r"],
        [:execute_query, "START n = node(*) WHERE ID(n) > 0 DELETE n"])
  end
end