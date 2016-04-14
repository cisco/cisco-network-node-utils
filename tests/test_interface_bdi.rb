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
require_relative '../lib/cisco_node_utils/interface'
require_relative '../lib/cisco_node_utils/bridge_domain'

include Cisco

# TestBdi - Minitest for Interface configuration of BDI interfaces.
class TestBdi < CiscoTestCase
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars
  attr_reader :bdi

  def self.runnable_methods
    # We don't have a separate YAML file to key off, so we check platform
    return super if node.product_id[/N7/]
    remove_method :setup
    remove_method :teardown
    [:unsupported]
  end

  def unsupported
    skip("Skipping #{self.class}; Bdi interfaces are not supported on the \
platform")
  end

  def setup
    super
    remove_all_bdis if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
    BridgeDomain.new('100')
    @bdi = Interface.new('Bdi100')
  end

  def remove_all_bdis
    Interface.interfaces.each do |int, obj|
      next unless int[/bdi/i]
      obj.destroy
    end
    remove_all_bridge_domains
  end

  def teardown
    remove_all_bdis
    super
  end

  def test_create_and_check_all_properties
    # Check all the default values
    assert_equal(@bdi.default_vrf, @bdi.vrf)
    assert_equal(@bdi.default_ipv4_address, @bdi.ipv4_address)
    assert_equal(@bdi.default_ipv4_netmask_length, @bdi.ipv4_netmask_length)
    address = '8.7.1.1'
    length = 15

    @bdi.ipv4_addr_mask_set(address, length)
    assert_equal(address, @bdi.ipv4_address,
                 'Error: ipv4 address get value mismatch')
    assert_equal(length, @bdi.ipv4_netmask_length,
                 'Error: ipv4 netmask length get value mismatch')

    vrf = 'test'
    @bdi.vrf = vrf
    assert_equal(vrf, @bdi.vrf)
    @bdi.vrf = ''
    assert_equal(@bdi.default_vrf, @bdi.vrf)
  end
end
