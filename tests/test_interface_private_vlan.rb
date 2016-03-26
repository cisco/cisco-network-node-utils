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

include Cisco

# TestInterfaceSwitchport
# Parent class for specific types of switchport tests (below)
class TestInterfaceSwitchport < CiscoTestCase
  attr_reader :interface

  def setup
    super
    config('feature private-vlan', 'no feature vtp')
    @interface = Interface.new(interfaces[1])
  end

  def teardown
    # config("default interface ethernet #{interfaces_id[0]}")
    # config('no feature private-vlan')
    super
  end
end

# TestSwitchport - general interface switchport tests.
class TestSwitchport < TestInterfaceSwitchport
  def test_interface_switchport_private_host_mode
    if validate_property_excluded?('interface',
                                   'switchport_mode_private_vlan_host')
      assert_nil(interface.switchport_mode_private_vlan_host)
      assert_raises(Cisco::UnsupportedError) do
        interface.switchport_mode_private_vlan_host = 'host'
      end
      return
    else
      interface.switchport_mode_private_vlan_host = :host
      interface.switchport_mode_private_vlan_host = :promiscuous
    end
  end
end
