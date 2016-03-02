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
    # Load parameters for login
    address
    username
    password
    # Clear out the environment so we have control over which parameters
    # we provide to Node to connect with.
    @env_node = ENV['NODE']
    ENV['NODE'] = nil
    Node.instance_variable_set(:@instance, nil)
  end

  def teardown
    # Restore the environment
    ENV['NODE'] = @env_node
  end

  def test_connect_zero_arguments
    # No UDS present on the test host, so default logic fails to connect
    assert_raises(Cisco::ConnectionRefused) do
      Node.new
    end
    assert_raises(RuntimeError) do
      Node.instance
    end
  end

  def test_connect_one_argument
    assert_raises(TypeError, ArgumentError) do
      Node.new(address)
    end
    assert_raises(TypeError, ArgumentError) do
      Node.instance(address)
    end
  end

  def test_connect_two_arguments
    assert_raises(TypeError, ArgumentError) do
      Node.new(username, password)
    end
    assert_raises(TypeError, ArgumentError) do
      Node.instance(username, password)
    end
  end

  def test_connect_nil_username
    assert_raises(TypeError, ArgumentError) do
      Node.new(address, nil, password)
    end
    assert_raises(TypeError, ArgumentError) do
      Node.instance(address, nil, password)
    end
  end

  def test_connect_invalid_username
    assert_raises(TypeError, ArgumentError) do
      Node.new(address, self, password)
    end
    assert_raises(TypeError, ArgumentError) do
      Node.instance(address, self, password)
    end
  end

  def test_connect_username_zero_length
    assert_raises(ArgumentError) do
      Node.new(address, '', password)
    end
    assert_raises(ArgumentError) do
      Node.instance(address, '', password)
    end
  end

  def test_connect_nil_password
    assert_raises(TypeError, ArgumentError) do
      Node.new(address, username, nil)
    end
    assert_raises(TypeError, ArgumentError) do
      Node.instance(address, username, nil)
    end
  end

  def test_connect_invalid_password
    assert_raises(TypeError, ArgumentError) do
      Node.new(address, username, self)
    end
    assert_raises(TypeError, ArgumentError) do
      Node.instance(address, username, self)
    end
  end

  def test_connect_password_zero_length
    assert_raises(ArgumentError) do
      Node.new(address, username, '')
    end
    assert_raises(ArgumentError) do
      Node.instance(address, username, '')
    end
  end

  def test_connect
    node = Node.instance(address, username, password)
    node2 = Node.instance
    assert_equal(node, node2)
    assert_raises(RuntimeError) do
      Node.instance(address, 'hello', 'goodbye')
    end
  end
end
