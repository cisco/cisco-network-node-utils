require_relative 'spec_helper.rb'
require 'shared_examples_for_clients'
require 'cisco_node_utils/client'

describe Cisco::Client do
  it_behaves_like 'all clients'
end
