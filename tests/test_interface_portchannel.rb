# Copyright (c) 2014-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/interface'
require_relative '../lib/cisco_node_utils/interface_portchannel'

# TestX__CLASS_NAME__X - Minitest for X__CLASS_NAME__X node utility class
class TestInterfacePortChannel < CiscoTestCase
  # TESTS

  DEFAULT_NAME = 'port-channel134'

  def setup
    super
    config "no interface #{DEFAULT_NAME}"
  end

  def teardown
    config "no interface #{DEFAULT_NAME}"
    super
  end

  def n6k_platform?
    /N(5|6)/ =~ node.product_id
  end

  def create_port_channel(ifname=DEFAULT_NAME)
    InterfacePortChannel.new(ifname)
  end

  def test_get_set_port_hash_distribution
    skip('Platform does not support this property') if n6k_platform?
    interface = create_port_channel
    interface.port_hash_distribution = 'adaptive'
    assert_equal('adaptive', interface.port_hash_distribution)
    interface.port_hash_distribution = 'fixed'
    assert_equal('fixed', interface.port_hash_distribution)
    interface.port_hash_distribution =
      interface.default_port_hash_distribution
    assert_equal(interface.default_port_hash_distribution,
                 interface.port_hash_distribution)
  end

  def test_get_set_lacp_graceful_convergence
    interface = create_port_channel
    interface.lacp_graceful_convergence = false
    assert_equal(false, interface.lacp_graceful_convergence)
    interface.lacp_graceful_convergence =
      interface.default_lacp_graceful_convergence
    assert_equal(interface.default_lacp_graceful_convergence,
                 interface.lacp_graceful_convergence)
  end

  def test_get_set_lacp_min_links
    interface = create_port_channel
    interface.lacp_min_links = 5
    assert_equal(5, interface.lacp_min_links)
    interface.lacp_min_links = interface.default_lacp_min_links
    assert_equal(interface.default_lacp_min_links,
                 interface.lacp_min_links)
  end

  def test_get_set_lacp_max_bundle
    interface = create_port_channel
    interface.lacp_max_bundle = 10
    assert_equal(10, interface.lacp_max_bundle)
    interface.lacp_max_bundle =
      interface.default_lacp_max_bundle
    assert_equal(interface.default_lacp_max_bundle,
                 interface.lacp_max_bundle)
  end

  def test_get_set_lacp_suspend_individual
    interface = create_port_channel
    interface.lacp_suspend_individual = false
    assert_equal(false, interface.lacp_suspend_individual)
    interface.lacp_suspend_individual =
      interface.default_lacp_suspend_individual
    assert_equal(interface.default_lacp_suspend_individual,
                 interface.lacp_suspend_individual)
  end

  def test_get_set_port_load_defer
    skip('Platform does not support this property') if n6k_platform?
    interface = create_port_channel
    interface.port_load_defer = true
    assert_equal(true, interface.port_load_defer)
    interface.port_load_defer =
      interface.default_port_load_defer
    assert_equal(interface.default_port_load_defer,
                 interface.port_load_defer)
  end
end
