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
require_relative '../lib/cisco_node_utils/tacacs_server_group'
require_relative '../lib/cisco_node_utils/tacacs_server_host'

# Test class for Tacacs Server Group
class TestTacacsServerGroup < CiscoTestCase
  def clean_tacacs_config
    config('no feature tacacs',
           'feature tacacs')
  end

  def create_tacacsserverhost(name='defaulttest')
    TacacsServerHost.new(name)
  end

  def detach_tacacsserverhost(host)
    host.destroy
  end

  def detach_aaaservergroup(aaa_server_group)
    aaa_server_group.destroy
  end

  def create_aaa_group(group_name, server)
    config("aaa group server #{server} #{group_name}")
  end

  def destroy_aaa_group(group_name, server)
    config("no aaa group server #{server} #{group_name}")
  end

  def create_vrf(group_name, server, vrf_name)
    config("aaa group server #{server} #{group_name} ; use-vrf #{vrf_name}")
  end

  def create_deadtime(group_name, server, deadtime)
    config("aaa group server #{server} #{group_name} ; deadtime #{deadtime}")
  end

  def create_source_interface(group_name, server, interface)
    config("aaa group server #{server} #{group_name} ; " \
           "source-interface #{interface}")
  end

  def test_create_invalid_name_tacacs
    assert_raises(TypeError) do
      TacacsServerGroup.new(nil)
    end
  end

  def test_create_valid_tacacs
    group_name = 'Group1'
    aaa_group = TacacsServerGroup.new(group_name)
    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /#{group_name}/)

    detach_aaaservergroup(aaa_group)
  end

  def test_create_valid_multiple_tacacs
    group_name1 = 'Group1'
    group_name2 = 'Group2'
    aaa_group1 = TacacsServerGroup.new(group_name1)
    aaa_group2 = TacacsServerGroup.new(group_name2)

    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /#{group_name1}/)
    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /#{group_name2}/)

    detach_aaaservergroup(aaa_group1)
    detach_aaaservergroup(aaa_group2)
  end

  def test_collection_empty_tacacs
    clean_tacacs_config
    aaa_group_list = TacacsServerGroup.groups
    assert_empty(aaa_group_list,
                 'Error: TacacsServerGroup collection is not empty')
  end

  def test_collection_multi_tacacs
    clean_tacacs_config
    group_name1 = 'Group1'
    group_name2 = 'Group2'
    group_name3 = 'Group3'
    aaa_group1 = TacacsServerGroup.new(group_name1)

    groups = TacacsServerGroup.groups
    assert_equal(1, groups.size,
                 'Error: TacacsServerGroup collection reporting incorrect size')
    assert(groups.key?(group_name1),
           "Error: TacacsServerGroup collection does contain #{group_name1}")
    detach_aaaservergroup(aaa_group1)

    create_aaa_group(group_name2, 'tacacs+')
    create_aaa_group(group_name3, 'tacacs+')
    groups = TacacsServerGroup.groups
    refute_empty(groups, 'Error: TacacsServerGroup collection is not filled')
    assert_equal(2, groups.size,
                 'Error: TacacsServerGroup collection reporting incorrect size')
    assert(groups.key?(group_name2),
           "Error: TacacsServerGroup collection does contain #{group_name2}")
    assert(groups.key?(group_name3),
           "Error: TacacsServerGroup collection does contain #{group_name3}")

    destroy_aaa_group(group_name2, 'tacacs+')
    destroy_aaa_group(group_name3, 'tacacs+')
  end

  def test_servers_tacacs
    clean_tacacs_config
    server_name1 = 'server1'
    server_name2 = 'server2'
    server1 = create_tacacsserverhost(server_name1)
    server2 = create_tacacsserverhost(server_name2)

    aaa_group = TacacsServerGroup.new('Group1')

    # pre check that default servers are empty
    default_server = aaa_group.default_servers
    assert_empty(default_server, 'Error: Default Servers are not empty')

    aaa_group.servers = [server_name1, server_name2]

    # Check collection size
    servers = aaa_group.servers
    assert_equal(2, servers.size,
                 'Error: Collection is not two servers')
    assert(servers.include?('server1'),
           "Error: Collection does not contain #{server_name1}")
    assert(servers.include?('server2'),
           "Error: Collection does not contain #{server_name2}")

    detach_aaaservergroup(aaa_group)
    detach_tacacsserverhost(server1)
    detach_tacacsserverhost(server2)
  end

  def test_add_server_tacacs
    server_name1 = 'server1'
    server_name2 = 'server2'
    server1 = create_tacacsserverhost(server_name1)
    server2 = create_tacacsserverhost(server_name2)

    aaa_group = TacacsServerGroup.new('Group1')
    aaa_group.servers = [server_name1, server_name2]

    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server #{server_name1}/)
    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server #{server_name2}/)

    detach_aaaservergroup(aaa_group)
    detach_tacacsserverhost(server1)
    detach_tacacsserverhost(server2)
  end

  def test_remove_server_tacacs
    clean_tacacs_config
    server_name1 = 'server1'
    server_name2 = 'server2'
    server1 = create_tacacsserverhost(server_name1)
    server2 = create_tacacsserverhost(server_name2)

    aaa_group = TacacsServerGroup.new('Group1')
    aaa_group.servers = [server_name1, server_name2]

    # Check collection size
    servers = aaa_group.servers
    assert_equal(2, servers.size,
                 'Error: Collection is not two servers')

    # Now remove them and then check again
    aaa_group.servers = [server_name2]
    refute_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server #{server_name1}/)

    aaa_group.servers = []
    refute_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server #{server_name2}/)

    detach_aaaservergroup(aaa_group)
    detach_tacacsserverhost(server1)
    detach_tacacsserverhost(server2)
  end

  def test_remove_server_twice_tacacs
    clean_tacacs_config
    server_name1 = 'server1'
    server_name2 = 'server2'
    server1 = create_tacacsserverhost(server_name1)
    server2 = create_tacacsserverhost(server_name2)

    aaa_group = TacacsServerGroup.new('Group1')
    aaa_group.servers = [server_name1, server_name2]

    # Check collection size
    servers = aaa_group.servers
    assert_equal(2, servers.size,
                 'Error: Collection is not two servers')

    # Remove server 1
    aaa_group.servers = [server_name2]
    refute_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server #{server_name1}/)

    # Now remove server 2
    aaa_group.servers = []
    refute_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server #{server_name2}/)

    # Check collection size
    servers = aaa_group.servers
    assert_empty(servers, 'Error: Collection not empty')

    detach_aaaservergroup(aaa_group)
    detach_tacacsserverhost(server1)
    detach_tacacsserverhost(server2)
  end

  def test_get_vrf_tacacs
    group_name1 = 'Group1'
    aaa_group = TacacsServerGroup.new(group_name1)

    vrf = cmd_ref.lookup('tacacs_server_group', 'vrf').default_value
    assert_equal(vrf, aaa_group.vrf,
                 'Error: TacacsServerGroup, vrf not default')

    vrf = 'TESTME'
    create_vrf(group_name1, 'tacacs+', vrf)
    assert_equal(vrf, aaa_group.vrf,
                 'Error: TacacsServerGroup, vrf not configured')

    vrf = cmd_ref.lookup('tacacs_server_group', 'vrf').default_value
    aaa_group.vrf = vrf
    assert_equal(vrf, aaa_group.vrf,
                 'Error: TacacsServerGroup, vrf not restored to default')

    detach_aaaservergroup(aaa_group)
  end

  def test_get_default_vrf_tacacs
    aaa_group = TacacsServerGroup.new('Group1')
    assert_equal(cmd_ref.lookup('tacacs_server_group', 'vrf').default_value,
                 aaa_group.default_vrf,
                 'Error: TacacsServerGroup, default vrf incorrect')
    detach_aaaservergroup(aaa_group)
  end

  def test_set_vrf_tacacs
    vrf = 'management-123'
    aaa_group = TacacsServerGroup.new('Group1')
    aaa_group.vrf = vrf
    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /use-vrf #{vrf}/)

    # Invalid case
    assert_raises(TypeError) do
      aaa_group.vrf = 2450
    end
    detach_aaaservergroup(aaa_group)
  end

  def test_get_deadtime_tacacs
    group_name = 'Group1'
    aaa_group = TacacsServerGroup.new(group_name)

    deadtime = cmd_ref.lookup('tacacs_server_group', 'deadtime').default_value
    assert_equal(deadtime, aaa_group.deadtime,
                 'Error: TacacsServerGroup, deadtime not default')

    deadtime = 850
    create_deadtime(group_name, 'tacacs+', deadtime)
    assert_equal(deadtime, aaa_group.deadtime,
                 'Error: TacacsServerGroup, deadtime not configured')

    deadtime = cmd_ref.lookup('tacacs_server_group', 'deadtime').default_value
    aaa_group.deadtime = deadtime
    assert_equal(deadtime, aaa_group.deadtime,
                 'Error: TacacsServerGroup, deadtime not restored to default')

    detach_aaaservergroup(aaa_group)
  end

  def test_get_default_deadtime_tacacs
    aaa_group = TacacsServerGroup.new('Group1')
    assert_equal(
      cmd_ref.lookup('tacacs_server_group', 'deadtime').default_value,
      aaa_group.default_deadtime,
      'Error: TacacsServerGroup, default deadtime incorrect')
    detach_aaaservergroup(aaa_group)
  end

  def test_set_deadtime_tacacs
    deadtime = 1250
    aaa_group = TacacsServerGroup.new('Group1')
    aaa_group.deadtime = deadtime
    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /deadtime #{deadtime}/,
                      msg:     'Error: deadtime not configured')
    # Invalid case
    deadtime = 2450
    assert_raises(CliError) do
      aaa_group.deadtime = deadtime
    end
    detach_aaaservergroup(aaa_group)
  end

  def test_get_source_interface_tacacs
    group_name = 'Group1'
    aaa_group = TacacsServerGroup.new(group_name)
    intf =
      cmd_ref.lookup('tacacs_server_group', 'source_interface').default_value
    assert_equal(intf, aaa_group.source_interface,
                 'Error: TacacsServerGroup, source-interface set')

    intf = 'Ethernet1/1'
    create_source_interface(group_name, 'tacacs+', intf)
    assert_equal(intf, aaa_group.source_interface,
                 'Error: TacacsServerGroup, source-interface not correct')

    intf = 'Ethernet1/32'
    create_source_interface(group_name, 'tacacs+', intf)
    assert_equal(intf, aaa_group.source_interface,
                 'Error: TacacsServerGroup, source-interface not correct')

    detach_aaaservergroup(aaa_group)
  end

  def test_get_default_source_interface_tacacs
    aaa_group = TacacsServerGroup.new('Group1')
    assert_equal(
      cmd_ref.lookup('tacacs_server_group', 'source_interface').default_value,
      aaa_group.default_source_interface,
      'Error: Aaa_Group Server, default source-interface incorrect')
    detach_aaaservergroup(aaa_group)
  end

  def test_set_source_interface_tacacs
    intf =
      cmd_ref.lookup('tacacs_server_group', 'source_interface').default_value
    aaa_group = TacacsServerGroup.new('Group1')
    assert_equal(intf, aaa_group.source_interface,
                 'Error: Aaa_Group Server, source-interface not default')

    aaa_group.source_interface = 'loopback1'
    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /source-interface loopback1/,
                      msg:     'Error: source-interface not correct')

    aaa_group.source_interface =
      cmd_ref.lookup('tacacs_server_group', 'source_interface').default_value
    refute_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /source-interface loopback1/)

    # Invalid case
    state = true
    assert_raises(TypeError) do
      aaa_group.source_interface = state
    end

    detach_aaaservergroup(aaa_group)
  end

  # tacacs_server_groups method is the same as groups, added for netdev
  # compatibility, make sure output is the same
  def test_groups_methods_equality
    aaagroup1 = TacacsServerGroup.new('test1')
    aaagroup2 = TacacsServerGroup.new('test2')
    aaagroup3 = TacacsServerGroup.new('test3')

    groups1 = TacacsServerGroup.groups.sort
    groups2 = TacacsServerGroup.tacacs_server_groups.sort

    assert_equal(groups1, groups2)

    detach_aaaservergroup(aaagroup1)
    detach_aaaservergroup(aaagroup2)
    detach_aaaservergroup(aaagroup3)
  end

  def test_destroy_tacacs
    group_name = 'Group1'
    aaa_group = TacacsServerGroup.new(group_name)

    detach_aaaservergroup(aaa_group)
    refute_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /#{group_name}/)
  end
end
