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

Node.lazy_connect = true # we'll specify the connection info later

# TestNode - Minitest for core functionality of Node class
class TestNode < TestCase
  def setup
  end

  def teardown
    GC.start
  end

  # As Node is now a singleton, we cannot instantiate it.

  def test_node_create_not_allowed
    assert_raises(NoMethodError) do
      Node.new
    end
  end

  def test_node_connect_zero_arguments
    node = Node.instance
    # No UDS present on the test host, so default logic fails to connect
    assert_raises(RuntimeError) do
      node.connect
    end
  end

  def test_node_connect_one_argument
    node = Node.instance
    assert_raises(TypeError) do
      node.connect(address)
    end
  end

  def test_node_connect_two_arguments
    node = Node.instance
    assert_raises(TypeError) do
      node.connect(username, password)
    end
  end

  def test_node_connect_nil_username
    node = Node.instance
    assert_raises(TypeError) do
      node.connect(address, nil, password)
    end
  end

  def test_node_connect_invalid_username
    node = Node.instance
    assert_raises(TypeError) do
      node.connect(address, node, password)
    end
  end

  def test_node_connect_username_zero_length
    node = Node.instance
    assert_raises(ArgumentError) do
      node.connect(address, '', password)
    end
  end

  def test_node_connect_nil_password
    node = Node.instance
    assert_raises(TypeError) do
      node.connect(address, username, nil)
    end
  end

  def test_node_connect_invalid_password
    node = Node.instance
    assert_raises(TypeError) do
      node.connect(address, username, node)
    end
  end

  def test_node_connect_password_zero_length
    node = Node.instance
    assert_raises(ArgumentError) do
      node.connect(address, username, '')
    end
  end

  def test_node_connect
    node = Node.instance
    node.connect(address, username, password)
  end
end
