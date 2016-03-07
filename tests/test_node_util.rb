# Copyright (c) 2016 Cisco and/or its affiliates.
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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/node_util'

# TestNodeUtil - Minitest for NodeUtil class
class TestNodeUtil < CiscoTestCase
  attr_reader :nu
  def setup
    @nu = NodeUtil.new
  end

  def test_node
    assert_equal(node, nu.node)
    assert_equal(node, NodeUtil.node)
  end

  def test_client
    assert_equal(node.client, nu.client)
    assert_equal(node.client, NodeUtil.client)
  end

  def test_config_get
    result = node.config_get('show_version', 'system_image')
    result2 = nu.config_get('show_version', 'system_image')
    result3 = NodeUtil.config_get('show_version', 'system_image')
    assert_equal(node.system, result)
    assert_equal(result, result2)
    assert_equal(result, result3)
  end

  def test_config_get_default
    result = node.config_get_default('bgp', 'graceful_restart_timers_restart')
    result2 = nu.config_get_default('bgp', 'graceful_restart_timers_restart')
    result3 = NodeUtil.config_get_default('bgp',
                                          'graceful_restart_timers_restart')
    assert_equal(120, result)
    assert_equal(result, result2)
    assert_equal(result, result3)
  end

  def test_config_set_error_handling
    # The Node error has no context information
    e = assert_raises(Cisco::CliError) do
      node.config_set('interface', 'shutdown',
                      name: interfaces[0], state: 'foobar')
    end
    assert_match(/^The command '.*shutdown' was rejected with error:/,
                 e.message)
    rejected_input = e.rejected_input
    clierror = e.clierror

    # The NodeUtil class error just provides the class name by default...
    e = assert_raises(Cisco::CliError) do
      NodeUtil.config_set('interface', 'shutdown',
                          name: interfaces[0], state: 'foobar')
    end
    assert_match(
      /^\[Cisco::NodeUtil\] The command '.*shutdown' was rejected with error:/,
      e.message)
    # Make sure error context from the Node was preserved
    assert_equal(rejected_input, e.rejected_input)
    assert_equal(clierror, e.clierror)

    # ...but uses self.to_s if implemented
    def NodeUtil.to_s
      'Hello world'
    end
    e = assert_raises(Cisco::CliError) do
      NodeUtil.config_set('interface', 'shutdown',
                          name: interfaces[0], state: 'foobar')
    end
    assert_match(
      /^\[Hello world\] The command '.*shutdown' was rejected with error:/,
      e.message)
    # Make sure error context from the Node was preserved
    assert_equal(rejected_input, e.rejected_input)
    assert_equal(clierror, e.clierror)

    # Similarly, the nu instance error provides the instance by default...
    e = assert_raises(Cisco::CliError) do
      nu.config_set('interface', 'shutdown',
                    name: interfaces[0], state: 'foobar')
    end
    assert_match(
      /^\[#<Cisco::NodeUtil:0x.*>\] The command '.*shutdown' was rejected/,
      e.message)
    # Make sure error context from the Node was preserved
    assert_equal(rejected_input, e.rejected_input)
    assert_equal(clierror, e.clierror)

    # ...but is happy to use the instance to_s
    def nu.to_s
      'NodeUtil #1'
    end
    e = assert_raises(Cisco::CliError) do
      nu.config_set('interface', 'shutdown',
                    name: interfaces[0], state: 'foobar')
    end
    assert_match(
      /^\[NodeUtil #1\] The command '.*shutdown' was rejected with error:/,
      e.message)
    # Make sure error context from the Node was preserved
    assert_equal(rejected_input, e.rejected_input)
    assert_equal(clierror, e.clierror)
  end
end
