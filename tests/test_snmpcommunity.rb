# Copyright (c) 2013-2015 Cisco and/or its affiliates.
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

require File.expand_path('../ciscotest', __FILE__)
require File.expand_path('../../lib/cisco_node_utils/snmpcommunity', __FILE__)

def cleanup_snmp_communities(snmpcommunities)
  snmpcommunities.each_value(&:destroy)
end

def cleanup_snmpcommunity(community)
  community.destroy
end

# TestSnmpCommunity - Minitest for SnmpCommunity node utility
class TestSnmpCommunity < CiscoTestCase
  SNMP_COMMUNITY_NAME_STR = 128
  SNMP_GROUP_NAME_STR = 128
  DEFAULT_SNMP_COMMUNITY_GROUP = 'network-operator'
  DEFAULT_SNMP_COMMUNITY_ACL = ''

  def test_snmpcommunity_collection_empty
    # This test requires all the snmp communities removed from device
    s = @device.cmd('show run snmp all | no-more')
    cmd_prefix = 'snmp-server community'
    # puts "s : #{s}"
    pattern = /#{cmd_prefix}\s\S+\sgroup\s\S+/
    until (md = pattern.match(s)).nil?
      # puts "md : #{md}"
      @device.cmd('configure terminal')
      @device.cmd("no #{md}")
      @device.cmd('end')
      node.cache_flush
      s = md.post_match
    end
    snmpcommunities = SnmpCommunity.communities
    assert_equal(true, snmpcommunities.empty?,
                 'SnmpCommunity collection is not empty')
  end

  def test_snmpcommunity_collection_not_empty
    # This test require some snmp community exist in device
    @device.cmd('configure terminal')
    @device.cmd('snmp-server community com1 group network-admin')
    @device.cmd('snmp-server community com2')
    @device.cmd('end')
    node.cache_flush
    snmpcommunities = SnmpCommunity.communities
    assert_equal(false, snmpcommunities.empty?,
                 'SnmpCommunity collection is empty')
    cleanup_snmp_communities(snmpcommunities)
  end

  def test_snmpcommunity_collection_valid
    # This test require some snmp community exist in device
    @device.cmd('configure terminal')
    @device.cmd('snmp-server community com12 group network-operator')
    @device.cmd('snmp-server community com22 group network-admin')
    @device.cmd('end')
    node.cache_flush
    # get collection
    snmpcommunities = SnmpCommunity.communities
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server community'
    snmpcommunities.each do |name, snmpcommunity|
      line = /#{cmd}\s#{name}\sgroup\s#{snmpcommunity.group}/.match(s)
      # puts "line: #{line}"
      assert_equal(false, line.nil?)
    end
    cleanup_snmp_communities(snmpcommunities)
  end

  def test_snmpcommunity_create_name_nil
    assert_raises(TypeError) do
      SnmpCommunity.new(nil, 'network-operator')
    end
  end

  def test_snmpcommunity_create_group_nil
    assert_raises(TypeError) do
      SnmpCommunity.new('test', nil)
    end
  end

  def test_snmpcommunity_create_name_zero_length
    assert_raises(Cisco::CliError) do
      SnmpCommunity.new('', 'network-operator')
    end
  end

  def test_snmpcommunity_create_group_zero_length
    assert_raises(Cisco::CliError) do
      SnmpCommunity.new('test', '')
    end
  end

  def test_snmpcommunity_create_name_too_long
    name = 'co' + 'c' * SNMP_COMMUNITY_NAME_STR
    assert_raises(Cisco::CliError) do
      SnmpCommunity.new(name, 'network-operator')
    end
  end

  def test_snmpcommunity_create_group_too_long
    group = 'gr' + 'g' * SNMP_GROUP_NAME_STR
    assert_raises(Cisco::CliError) do
      SnmpCommunity.new('test', group)
    end
  end

  def test_snmpcommunity_create_group_invalid
    name = 'ciscotest'
    group = 'network-operator-invalid'
    assert_raises(Cisco::CliError) do
      SnmpCommunity.new(name, group)
    end
  end

  def test_snmpcommunity_create_valid
    name = 'cisco'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server community'
    line = /#{cmd}\s#{name}\sgroup\s#{group}/.match(s)
    # puts "line: #{line}"
    assert_equal(false, line.nil?)
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_snmpcommunity_create_with_name_alphanumeric_char
    name = 'cisco128lab'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server community'
    line = /#{cmd}\s#{name}\sgroup\s#{group}/.match(s)
    # puts "line: #{line}"
    assert_equal(false, line.nil?)
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_snmpcommunity_get_group
    name = 'ciscogetgrp'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    assert_equal(snmpcommunity.group, group)
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_snmpcommunity_group_set_zero_length
    name = 'ciscogroupsetcom'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    assert_raises(Cisco::CliError) do
      snmpcommunity.group = ''
    end
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_snmpcommunity_group_set_too_long
    name = 'ciscogroupsetcom'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    assert_raises(Cisco::CliError) do
      snmpcommunity.group = 'group123456789c123456789c123456789c12345'
    end
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_snmpcommunity_group_set_invalid
    name = 'ciscogroupsetcom'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    assert_raises(Cisco::CliError) do
      snmpcommunity.group = 'testgroup'
    end
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_snmpcommunity_group_set_valid
    name = 'ciscogroupsetcom'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    # new group
    group = 'network-admin'
    snmpcommunity.group = group
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server community'
    line = /#{cmd}\s#{name}\sgroup\s#{group}/.match(s)
    assert_equal(false, line.nil?)
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_snmpcommunity_group_set_default
    name = 'ciscogroupsetcom'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    # new group identity
    group = 'vdc-admin'
    snmpcommunity.group = group
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server community'
    line = /#{cmd}\s#{name}\sgroup\s#{group}/.match(s)
    # puts line
    assert_equal(false, line.nil?)

    # Restore group default
    group = SnmpCommunity.default_group
    snmpcommunity.group = group
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server community'
    line = /#{cmd}\s#{name}\sgroup\s#{group}/.match(s)
    # puts line
    assert_equal(false, line.nil?)

    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_snmpcommunity_destroy_valid
    name = 'ciscotest'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    snmpcommunity.destroy
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server community'
    line = /#{cmd}\s#{name}\sgroup\s#{group}/.match(s)
    assert_equal(true, line.nil?)
  end

  def test_snmpcommunity_acl_get_no_acl
    name = 'cisconoaclget'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    assert_equal(snmpcommunity.acl, '')
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_snmpcommunity_acl_get
    name = 'ciscoaclget'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    snmpcommunity.acl = 'ciscoacl'
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server community'
    line = /#{cmd}\s#{name}\suse-acl\s\S+/.match(s)
    acl = line.to_s.gsub(/#{cmd}\s#{name}\suse-acl\s/, '').strip
    assert_equal(snmpcommunity.acl, acl)
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_snmpcommunity_acl_set_nil
    name = 'cisco'
    group = 'network-operator'
    snmpcommunity = SnmpCommunity.new(name, group)
    assert_raises(TypeError) do
      snmpcommunity.acl = nil
    end
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_snmpcommunity_acl_set_valid
    name = 'ciscoadmin'
    group = 'network-admin'
    acl = 'ciscoadminacl'
    snmpcommunity = SnmpCommunity.new(name, group)
    snmpcommunity.acl = acl
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server community'
    line = /#{cmd}\s#{name}\suse-acl\s#{acl}/.match(s)
    # puts "line: #{line}"
    assert_equal(false, line.nil?)
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_snmpcommunity_acl_set_zero_length
    name = 'ciscooper'
    group = 'network-operator'
    acl = 'ciscooperacl'
    snmpcommunity = SnmpCommunity.new(name, group)
    # puts "set acl #{acl}"
    snmpcommunity.acl = acl
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server community'
    line = /#{cmd}\s#{name}\suse-acl\s#{acl}/.match(s)
    # puts "line: #{line}"
    assert_equal(false, line.nil?)
    # remove acl
    snmpcommunity.acl = ''
    s = @device.cmd('show run snmp all | no-more')
    line = /#{cmd}\s#{name}\suse-acl\s#{acl}/.match(s)
    # puts "line: #{line}"
    assert_equal(true, line.nil?)
    cleanup_snmpcommunity(snmpcommunity)
  end

  def test_snmpcommunity_acl_set_default
    name = 'cisco'
    group = 'network-operator'
    acl = 'cisco_test_acl'
    snmpcommunity = SnmpCommunity.new(name, group)
    snmpcommunity.acl = acl
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server community'
    line = /#{cmd}\s#{name}\suse-acl\s#{acl}/.match(s)
    # puts "line: #{line}"
    assert_equal(false, line.nil?)

    # Check default_acl
    assert_equal(DEFAULT_SNMP_COMMUNITY_ACL,
                 SnmpCommunity.default_acl,
                 'Error: Snmp Community, default ACL not correct value')

    # Set acl to default
    acl = SnmpCommunity.default_acl
    snmpcommunity.acl = acl
    s = @device.cmd('show run snmp all | no-more')
    line = /#{cmd}\s#{name}\suse-acl\s#{acl}/.match(s)
    # puts "line: #{line}"
    assert_equal(true, line.nil?)
    cleanup_snmpcommunity(snmpcommunity)
  end
end
