# Copyright (c) 2013-2016 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'basetest'

require_relative '../lib/cisco_node_utils/node'
require_relative '../lib/cisco_node_utils/command_reference'

include Cisco

# TestNode - Minitest for core functionality of Node class
class TestNode < TestCase
  def setup
    super
    # Clear out the environment so we have control over which parameters
    # we provide to Node to connect with.
    Node.instance_variable_set(:@instance, nil)
  end

  def test_connect_no_environment
    environment = Node::Environment.default_environment_name
    Node::Environment.default_environment_name = '!@#$&@#$' # nonexistent
    # No UDS present on the test host, so default environment fails to connect
    assert_raises(Cisco::ConnectionRefused) do
      Node.new
    end
    assert_raises(Cisco::ConnectionRefused) do
      Node.instance
    end
  ensure
    Node::Environment.default_environment_name = environment
  end

  def test_singleton
    node = Node.instance
    node2 = Node.instance
    assert_equal(node, node2)
  end
end
