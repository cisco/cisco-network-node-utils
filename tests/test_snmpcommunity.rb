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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/snmpcommunity'

def cleanup_snmp_communities(snmpcommunities)
  snmpcommunities.each_value(&:destroy)
end

def cleanup_snmpcommunity(community)
  community.destroy
end

# TestSnmpCommunity - Minitest for SnmpCommunity node utility
class TestSnmpCommunity < CiscoTestCase
  @skip_unless_supported = 'snmp_community'

  SNMP_COMMUNITY_NAME_STR = 128
  SNMP_GROUP_NAME_STR = 128
  DEFAULT_SNMP_COMMUNITY_GROUP = 'network-operator'
  DEFAULT_SNMP_COMMUNITY_ACL = ''

  def setup
    super
    if platform != :ios_xr
      @default_show_command = 'show run snmp all | no-more'
    else
      @default_show_command = 'show running-config snmp'
    end
  end

  def test_collection_empty
    # This test requires all the snmp communities removed from device
    original_list = SnmpCommunity.communities
    cleanup_snmp_communities(original_list)

    snmpcommunities = SnmpCommunity.communities
    assert_equal(true, snmpcommunities.empty?,
                 'SnmpCommunity collection is not empty')
  end

  def test_collection_not_empty
    snmpcommunities = SnmpCommunity.communities
    cleanup_snmp_communities(snmpcommunities)

    # This test require some snmp community exist in device
    if platform != :ios_xr
      config('snmp-server community com1 group network-admin',
             'snmp-server community com2')
    else
      config('snmp-server community com1',
             'snmp-server community com2')
    end
    snmpcommunities = SnmpCommunity.communities

    assert_equal(false, snmpcommunities.empty?,
                 'SnmpCommunity collection is empty')
    cleanup_snmp_communities(snmpcommunities)
  end

  def test_collection_valid
    # This test require some snmp community exist in device
    if platform != :ios_xr
      config('snmp-server community com12 group network-operator',
             'snmp-server community com22 group network-admin')
    else
      config('snmp-server community com12',
             'snmp-server community com22')
    end
    # get collection

    snmpcommunities = SnmpCommunity.communities
    if platform != :ios_xr
      s = @device.cmd('show run snmp all | no-more')
    else
      s = @device.cmd('show running-config snmp')
    end
    cmd = 'snmp-server community'
    snmpcommunities.each do |name, _snmpcommunity|
      line = /#{cmd}\s#{name}\s.*/.match(s)
      # puts "line: #{line}"
      assert_equal(false, line.nil?)
    end
    cleanup_snmp_communities(snmpcommunities)
  end

  def test_create_name_nil
    assert_raises(TypeError) do
      SnmpCommunity.new(nil, 'network-operator')
    end
  end

  def test_create_group_nil
    assert_raises(TypeError) do
      SnmpCommunity.new('test', nil)
    end
  end

  def test_create_name_zero_length
    assert_raises(Cisco::CliError) do
      SnmpCommunity.new('', 'network-operator')
    end
  end

  def test_create_group_zero_length
    assert_raises(Cisco::CliError) do
      SnmpCommunity.new('test', '')
    end
  end

  def test_create_name_too_long
    name = 'co' + 'c' * SNMP_COMMUNITY_NAME_STR
    assert_raises(Cisco::CliError) do
      if platform != :ios_xr
        SnmpCommunity.new(name, 'network-operator')
      else
        SnmpCommunity.new(name, '')
      end
    end
  end

  def test_create_group_too_long
    group = 'gr' + 'g' * SNMP_GROUP_NAME_STR
    assert_raises(Cisco::CliError) do
      SnmpCommunity.new('test', group)
    end
  end

  def test_create_group_invalid
    name = 'ciscotest'
    group = 'network-operator-invalid'
    skip if platform == :ios_xr
    assert_raises(Cisco::CliError) do
      SnmpCommunity.new(name, group)
    end
  end

  def test_create_valid
    name = 'cisco'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    if platform != :ios_xr
      assert_show_match(
        pattern: /snmp-server community\s#{name}\sgroup\s#{group}/)
    else
      assert_show_match(
        pattern: /snmp-server community\s#{name}/)
      assert_show_match(
        pattern: /snmp-server group\s#{group}/)
      assert_show_match(
        pattern: /snmp-server community-map\s#{name}\starget-list\s#{group}/)
    end
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_name_alpha
    name = 'cisco128lab'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    if platform != :ios_xr
      assert_show_match(
        pattern: /snmp-server community\s#{name}\sgroup\s#{group}/)
    else
      assert_show_match(
        pattern: /snmp-server community\s#{name}/)
      assert_show_match(
        pattern: /snmp-server group\s#{group}/)
      assert_show_match(
        pattern: /snmp-server community-map\s#{name}\starget-list\s#{group}/)
    end
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_get_group
    name = 'ciscogetgrp'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    assert_equal(snmpcommunity.group, group)
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_get_group_complex_name
    skip("Test not supported on #{product_tag} due to CSCva63814") if product_tag[/n5|6|7k/]
    names = ['C0mplex()Community!', 'C#', 'C$', 'C%', 'C^', 'C&', 'C*',
             'C-', 'C=', 'C<', 'C,', 'C.', 'C/', 'C|', 'C{}[]']
    group = 'network-admin'
    names.each do |name|
      sc = SnmpCommunity.new(name, group)
      assert_equal(group, sc.group)
      cleanup_snmpcommunity(sc)
    end
  end

  def test_group_set_zero_length
    name = 'ciscogroupsetcom'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    assert_raises(Cisco::CliError) do
      snmpcommunity.group = ''
    end
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_group_set_too_long
    skip if platform == :ios_xr
    name = 'ciscogroupsetcom'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    assert_raises(Cisco::CliError) do
      snmpcommunity.group = 'group123456789c123456789c123456789c12345'
    end
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_group_set_invalid
    skip if platform == :ios_xr
    name = 'ciscogroupsetcom'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    assert_raises(Cisco::CliError) do
      snmpcommunity.group = 'testgroup'
    end
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_group_set_valid
    name = 'ciscogroupsetcom'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    # new group
    group = 'network-admin'
    snmpcommunity.group = group
    if platform != :ios_xr
      assert_show_match(
        pattern: /snmp-server community\s#{name}\sgroup\s#{group}/)
    else
      assert_show_match(
        pattern: /snmp-server community\s#{name}/)
      assert_show_match(
        pattern: /snmp-server group\s#{group}/)
      assert_show_match(
        pattern: /snmp-server community-map\s#{name}\starget-list\s#{group}/)
    end

    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_group_set_default
    name = 'ciscogroupsetcom'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    # new group identity
    group = 'vdc-admin'
    snmpcommunity.group = group
    if platform != :ios_xr
      assert_show_match(
        pattern: /snmp-server community\s#{name}\sgroup\s#{group}/)
    else
      assert_show_match(
        pattern: /snmp-server community\s#{name}/)
      assert_show_match(
        pattern: /snmp-server group\s#{group}/)
      assert_show_match(
        pattern: /snmp-server community-map\s#{name}\starget-list\s#{group}/)
    end

    # Restore group default
    group = SnmpCommunity.default_group
    snmpcommunity.group = group
    if platform != :ios_xr
      assert_show_match(
        pattern: /snmp-server community\s#{name}\sgroup\s#{group}/)
    else
      assert_show_match(
        pattern: /snmp-server community\s#{name}/)
      assert_show_match(
        pattern: /snmp-server group\s#{group}/)
      assert_show_match(
        pattern: /snmp-server community-map\s#{name}\starget-list\s#{group}/)
    end

    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_destroy_valid
    name = 'ciscotest'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    snmpcommunity.destroy
    if platform != :ios_xr
      refute_show_match(
        pattern: /snmp-server community\s#{name}\sgroup\s#{group}/)
    else
      refute_show_match(
        pattern: /snmp-server community\s#{name}/)
    end
  end

  def test_acl_get_no_acl
    name = 'cisconoaclget'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    assert_equal(snmpcommunity.acl, '')
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_acl_get
    name = 'ciscoaclget'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    snmpcommunity.acl = 'ciscoacl'
    if platform != :ios_xr
      line = assert_show_match(
        pattern: /snmp-server community\s#{name}\suse-acl\s\S+/)
      acl = line.to_s.gsub(/snmp-server community\s#{name}\suse-acl\s/, '').strip
      assert_equal(snmpcommunity.acl, acl)
    else
      line = assert_show_match(
        pattern: /snmp-server community\s#{name}\sIPv4\s\S+/)
      acl = line.to_s.gsub(/snmp-server community\s#{name}\sIPv4\s/, '').strip
      assert_equal(snmpcommunity.acl, acl)
    end
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_acl_set_nil
    name = 'cisco'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    assert_raises(TypeError) do
      snmpcommunity.acl = nil
    end
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_acl_set_valid
    name = 'ciscoadmin'
    group = 'network-admin'
    acl = 'ciscoadminacl'
    snmpcommunity = SnmpCommunity.new(name, group)
    snmpcommunity.acl = acl
    if platform != :ios_xr
      assert_show_match(
        pattern: /snmp-server community\s#{name}\suse-acl\s#{acl}/)
    else
      assert_show_match(
        pattern: /snmp-server community\s#{name}\sIPv4\s#{acl}/)
    end
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_acl_set_zero_length
    name = 'ciscooper'
    group = 'network-operator'
    acl = 'ciscooperacl'
    snmpcommunity = SnmpCommunity.new(name, group)
    # puts "set acl #{acl}"
    snmpcommunity.acl = acl
    if platform != :ios_xr
      assert_show_match(
        pattern: /snmp-server community\s#{name}\suse-acl\s#{acl}/)
    else
      assert_show_match(
        pattern: /snmp-server community\s#{name}\sIPv4\s#{acl}/)
    end
    # remove acl
    snmpcommunity.acl = ''
    if platform != :ios_xr
      refute_show_match(
        pattern: /snmp-server community\s#{name}\suse-acl\s#{acl}/)
    else
      refute_show_match(
        pattern: /snmp-server community\s#{name}\sIPv4\s#{acl}/)
    end
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_acl_set_default
    name = 'cisco'
    group = 'network-operator'
    acl = 'cisco_test_acl'
    snmpcommunity = SnmpCommunity.new(name, group)
    snmpcommunity.acl = acl
    if platform != :ios_xr
      assert_show_match(
        pattern: /snmp-server community\s#{name}\suse-acl\s#{acl}/)
    else
      assert_show_match(
        pattern: /snmp-server community\s#{name}\sIPv4\s#{acl}/)
    end

    # Check default_acl
    assert_equal(DEFAULT_SNMP_COMMUNITY_ACL,
                 SnmpCommunity.default_acl,
                 'Error: Snmp Community, default ACL not correct value')

    # Set acl to default
    acl = SnmpCommunity.default_acl
    snmpcommunity.acl = acl
    if platform != :ios_xr
      refute_show_match(
        pattern: /snmp-server community\s#{name}\suse-acl\s#{acl}/)
    else
      refute_show_match(
        pattern: /snmp-server community\s#{name}\sIPv4\s#{acl}/)
    end

    cleanup_snmpcommunity(snmpcommunity)
  end
end
