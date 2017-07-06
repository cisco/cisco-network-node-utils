# Copyright (c) 2017 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/object_group'
require_relative '../lib/cisco_node_utils/object_group_entry'

# TestObject_group - Minitest for Object_group
# node utility class
class TestObjectGroup < CiscoTestCase
  @skip_unless_supported = 'object_group'
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    @og_name_v4 = 'test-my-v4'
    @og_name_v6 = 'test-my-v6'
    @og_name_port = 'test-my-port'
    remove_all_object_groups if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    remove_all_object_groups
    super
  end

  def remove_all_object_groups
    ObjectGroup.object_groups.each do |_afis, types|
      types.each do |_type, grps|
        grps.values.each(&:destroy)
      end
    end
  end

  def test_create_object_group
    %w(ipv4 ipv6).each do |afi|
      og_name = afi[/ipv6/] ? @og_name_v6 : @og_name_v4
      og = ObjectGroup.new(afi, 'address', og_name)
      assert(ObjectGroup.object_groups[afi]['address'].key?(og_name))
      og.destroy
      assert_nil(ObjectGroup.object_groups[afi])
    end
    og_name = @og_name_port
    og = ObjectGroup.new('ipv4', 'port', og_name)
    assert(ObjectGroup.object_groups['ipv4']['port'].key?(og_name))
    og.destroy
    assert_nil(ObjectGroup.object_groups['ipv4'])
  end

  def entry_helper(afi, type, name, props=nil)
    test_hash = {
      address: 'host 1.1.1.1',
      port:    'eq 200',
    }
    test_hash.merge!(props) unless props.nil?

    ObjectGroup.new(afi, type, name)
    e = ObjectGroupEntry.new(afi, type, name, 10)
    e.entry_set(test_hash)
    e
  end

  def test_ipv4_address_host
    e = entry_helper('ipv4', 'address', @og_name_v4, port: nil)
    assert_equal('host 1.1.1.1', e.address)
    e = entry_helper('ipv4', 'address', @og_name_v4, address: 'host 2.2.2.2', port: nil)
    assert_equal('host 2.2.2.2', e.address)
  end

  def test_ipv4_address_prefix
    e = entry_helper('ipv4', 'address', @og_name_v4, address: '2.2.2.2/17', port: nil)
    assert_equal('2.2.2.2/17', e.address)
    e = entry_helper('ipv4', 'address', @og_name_v4, address: '3.3.3.3/31', port: nil)
    assert_equal('3.3.3.3/31', e.address)
  end

  def test_ipv4_address_netmask
    e = entry_helper('ipv4', 'address', @og_name_v4, address: '2.2.2.2 255.255.255.0', port: nil)
    assert_equal('2.2.2.2 255.255.255.0', e.address)
    e = entry_helper('ipv4', 'address', @og_name_v4, address: '3.3.3.3 10.11.12.13', port: nil)
    assert_equal('3.3.3.3 10.11.12.13', e.address)
  end

  def test_ipv6_address_host
    e = entry_helper('ipv6', 'address', @og_name_v6, address: 'host 2000::1', port: nil)
    assert_equal('host 2000::1', e.address)
    e = entry_helper('ipv6', 'address', @og_name_v6, address: 'host 2001::2', port: nil)
    assert_equal('host 2001::2', e.address)
  end

  def test_ipv6_address_prefix
    e = entry_helper('ipv6', 'address', @og_name_v6, address: '2000::1/127', port: nil)
    assert_equal('2000::1/127', e.address)
    e = entry_helper('ipv6', 'address', @og_name_v6, address: '2001::10/64', port: nil)
    assert_equal('2001::10/64', e.address)
  end

  def test_ipv4_port
    e = entry_helper('ipv4', 'port', @og_name_port, address: nil)
    assert_equal('eq 200', e.port)
    e = entry_helper('ipv4', 'port', @og_name_port, port: 'lt 100', address: nil)
    assert_equal('lt 100', e.port)
    e = entry_helper('ipv4', 'port', @og_name_port, port: 'neq 150', address: nil)
    assert_equal('neq 150', e.port)
    e = entry_helper('ipv4', 'port', @og_name_port, port: 'gt 350', address: nil)
    assert_equal('gt 350', e.port)
    e = entry_helper('ipv4', 'port', @og_name_port, port: 'range 400 1000', address: nil)
    assert_equal('range 400 1000', e.port)
  end
end
