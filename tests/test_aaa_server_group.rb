# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/aaa_server_group'
require_relative '../lib/cisco_node_utils/tacacs_server_host'

AAA_SERVER_GROUP_TACACS_SERVER = :tacacs
AAA_SERVER_GROUP_RADIUS_SERVER = :radius
DEFAULT_AAA_SERVER_GROUP_VRF = 'default'
DEFAULT_AAA_SERVER_GROUP_DEADTIME = 0
DEFAULT_AAA_SERVER_GROUP_SOURCE_INTERFACE = ''

# Test class for AAA Server Group
class TestAaaServerGroup < CiscoTestCase
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

  def test_create_invalid_type
    assert_raises(TypeError) do
      AaaServerGroup.new(node, 'Group1')
    end
  end

  def test_create_invalid_name_tacacs
    assert_raises(TypeError) do
      AaaServerGroup.new(nil, nil)
    end
  end

  def test_create_invalid_name_radius
    # TBD
  end

  def test_create_valid_tacacs
    group_name = 'Group1'
    aaa_group = AaaServerGroup.new(group_name, :tacacs)
    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /Group1/)

    detach_aaaservergroup(aaa_group)
  end

  def test_create_valid_radius
    # TBD
  end

  def test_create_valid_multiple_tacacs
    group_name1 = 'Group1'
    group_name2 = 'Group2'
    aaa_group1 = AaaServerGroup.new(group_name1, :tacacs)
    aaa_group2 = AaaServerGroup.new(group_name2, :tacacs)

    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /Group1/)
    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /Group2/)

    detach_aaaservergroup(aaa_group1)
    detach_aaaservergroup(aaa_group2)
  end

  def test_create_valid_multiple_radius
    # TBD
  end

  def test_get_parent_radius
    # TBD
  end

  def test_collection_empty_tacacs
    clean_tacacs_config
    aaa_group_list = AaaServerGroup.groups(AAA_SERVER_GROUP_TACACS_SERVER)
    assert_empty(aaa_group_list,
                 'Error: AaaServerGroup collection is not empty')
  end

  def test_collection_empty_radius
    # TBD
  end

  def test_collection_invalid_nil_radius
    # TBD
  end

  def test_collection_invalid_tacacs
    assert_raises(TypeError) do
      AaaServerGroup.groups('TEST')
    end
  end

  def test_collection_invalid_radius
    # TBD
  end

  def test_collection_single_tacacs
    clean_tacacs_config
    group_name1 = 'Group1'
    group_name2 = 'Group2'
    group_name3 = 'Group3'
    aaa_group1 = AaaServerGroup.new(group_name1, :tacacs)

    groups = AaaServerGroup.groups(AAA_SERVER_GROUP_TACACS_SERVER)
    refute_empty(groups, 'Error: AaaServerGroup collection is not filled')
    assert_equal(1, groups.size,
                 'Error: AaaServerGroup collection not reporting correct size')
    assert(groups.key?(group_name1),
           "Error: AaaServerGroup collection does contain #{group_name1}")
    detach_aaaservergroup(aaa_group1)

    create_aaa_group(group_name2, 'tacacs+')
    create_aaa_group(group_name3, 'tacacs+')
    groups = AaaServerGroup.groups(AAA_SERVER_GROUP_TACACS_SERVER)
    refute_empty(groups, 'Error: AaaServerGroup collection is not filled')
    assert_equal(2, groups.size,
                 'Error: AaaServerGroup collection not reporting correct size')
    assert(groups.key?(group_name2),
           "Error: AaaServerGroup collection does contain #{group_name2}")
    assert(groups.key?(group_name3),
           "Error: AaaServerGroup collection does contain #{group_name3}")

    destroy_aaa_group(group_name2, 'tacacs+')
    destroy_aaa_group(group_name3, 'tacacs+')
  end

  def test_collection_single_radius
    # TBD
  end

  def test_collection_multi_tacacs
    clean_tacacs_config
    group_name1 = 'Group1'
    group_name2 = 'Group2'
    group_name3 = 'Group3'
    aaa_group1 = AaaServerGroup.new(group_name1, :tacacs)

    aaa_group2 = AaaServerGroup.new(group_name2, :tacacs)

    aaa_group3 = AaaServerGroup.new(group_name3, :tacacs)

    groups = AaaServerGroup.groups(AAA_SERVER_GROUP_TACACS_SERVER)
    refute_empty(groups, 'Error: AaaServerGroup collection is not filled')
    assert_equal(3, groups.size,
                 'Error: AaaServerGroup collection not reporting correct size')
    assert(groups.key?(group_name1),
           "Error: AaaServerGroup collection does contain #{group_name1}")
    assert(groups.key?(group_name2),
           "Error: AaaServerGroup collection does contain #{group_name2}")
    assert(groups.key?(group_name3),
           "Error: AaaServerGroup collection does contain #{group_name3}")

    detach_aaaservergroup(aaa_group1)
    detach_aaaservergroup(aaa_group2)
    detach_aaaservergroup(aaa_group3)
  end

  def test_collection_multi_radius
    # TBD
  end

  def test_servers_tacacs
    clean_tacacs_config
    server_name1 = 'server1'
    server_name2 = 'server2'
    server1 = create_tacacsserverhost(server_name1)
    server2 = create_tacacsserverhost(server_name2)

    aaa_group = AaaServerGroup.new('Group1', :tacacs)

    # pre check that default servers are empty
    default_server = AaaServerGroup.default_servers
    assert_empty(default_server, 'Error: Default Servers are not empty')

    aaa_group.servers = [server_name1, server_name2]

    # Check collection size
    servers = aaa_group.servers.keys
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

  def test_servers_radius
    # TBD
  end

  def test_add_server_tacacs
    server_name1 = 'server1'
    server_name2 = 'server2'
    server1 = create_tacacsserverhost(server_name1)
    server2 = create_tacacsserverhost(server_name2)

    aaa_group = AaaServerGroup.new('Group1', :tacacs)
    aaa_group.servers = [server_name1, server_name2]

    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server1/)
    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server2/)

    detach_aaaservergroup(aaa_group)
    detach_tacacsserverhost(server1)
    detach_tacacsserverhost(server2)
  end

  def test_add_server_radius
    # TBD
  end

  def test_add_server_twice_tacacs
    clean_tacacs_config
    server_name1 = 'server1'
    server_name2 = 'server2'
    server1 = create_tacacsserverhost(server_name1)
    server2 = create_tacacsserverhost(server_name2)

    aaa_group = AaaServerGroup.new('Group1', :tacacs)
    # aaa_group.servers = [server_name1, server_name2, server_name2]
    # this behavior is different on n9k vs n3k, so comment out for now
    # n3k throws a CLIError and n9k silently ignores
    aaa_group.servers = [server_name1, server_name2]

    servers = aaa_group.servers
    assert_equal(2, servers.size,
                 'Error: Collection is not two servers')

    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server server1/)
    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server server2/)

    detach_aaaservergroup(aaa_group)
    detach_tacacsserverhost(server1)
    detach_tacacsserverhost(server2)
  end

  def test_add_server_twice_radius
    # TBD
  end

  def test_remove_server_tacacs
    clean_tacacs_config
    server_name1 = 'server1'
    server_name2 = 'server2'
    server1 = create_tacacsserverhost(server_name1)
    server2 = create_tacacsserverhost(server_name2)

    aaa_group = AaaServerGroup.new('Group1', :tacacs)
    aaa_group.servers = [server_name1, server_name2]

    # Check collection size
    servers = aaa_group.servers
    assert_equal(2, servers.size,
                 'Error: Collection is not two servers')

    # Now remove them and then check again
    aaa_group.servers = [server_name2]
    refute_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server server1/)

    aaa_group.servers = []
    refute_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server server2/)

    detach_aaaservergroup(aaa_group)
    detach_tacacsserverhost(server1)
    detach_tacacsserverhost(server2)
  end

  def test_remove_server_radius
    # TBD
  end

  def test_remove_server_twice_tacacs
    clean_tacacs_config
    server_name1 = 'server1'
    server_name2 = 'server2'
    server1 = create_tacacsserverhost(server_name1)
    server2 = create_tacacsserverhost(server_name2)

    aaa_group = AaaServerGroup.new('Group1', :tacacs)
    aaa_group.servers = [server_name1, server_name2]

    # Check collection size
    servers = aaa_group.servers
    assert_equal(2, servers.size,
                 'Error: Collection is not two servers')

    # Now remove them and then check again
    aaa_group.servers = [server_name2]
    refute_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server server1/)

    # Now remove server 1 again
    aaa_group.servers = []
    refute_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /server server2/)

    # Check collection size
    servers = aaa_group.servers
    assert_empty(servers, 'Error: Collection not empty')

    detach_aaaservergroup(aaa_group)
    detach_tacacsserverhost(server1)
    detach_tacacsserverhost(server2)
  end

  def test_remove_server_twice_radius
    # TBD
  end

  def test_get_vrf_tacacs
    group_name1 = 'Group1'
    aaa_group = AaaServerGroup.new(group_name1, :tacacs)

    vrf = DEFAULT_AAA_SERVER_GROUP_VRF
    assert_equal(vrf, aaa_group.vrf,
                 'Error: AaaServerGroup, vrf not default')

    vrf = 'TESTME'
    create_vrf(group_name1, 'tacacs+', vrf)
    assert_equal(vrf, aaa_group.vrf,
                 'Error: AaaServerGroup, vrf not configured')

    vrf = DEFAULT_AAA_SERVER_GROUP_VRF
    aaa_group.vrf = vrf
    assert_equal(vrf, aaa_group.vrf,
                 'Error: AaaServerGroup, vrf not restored to default')

    detach_aaaservergroup(aaa_group)
  end

  def test_get_vrf_radius
    # TBD
  end

  def test_get_default_vrf_tacacs
    aaa_group = AaaServerGroup.new('Group1', :tacacs)
    assert_equal(DEFAULT_AAA_SERVER_GROUP_VRF,
                 AaaServerGroup.default_vrf,
                 'Error: AaaServerGroup, default vrf incorrect')
    detach_aaaservergroup(aaa_group)
  end

  def test_get_default_vrf_radius
    # TBD
  end

  def test_set_vrf_tacacs
    vrf = 'management-123'
    aaa_group = AaaServerGroup.new('Group1', :tacacs)
    aaa_group.vrf = vrf
    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /use-vrf management-123/)

    # Invalid case
    vrf = 2450
    assert_raises(TypeError) do
      aaa_group.vrf = vrf
    end
    detach_aaaservergroup(aaa_group)
  end

  def test_set_vrf_radius
    # TBD
  end

  def test_get_deadtime_tacacs
    group_name = 'Group1'
    aaa_group = AaaServerGroup.new(group_name, :tacacs)

    deadtime = DEFAULT_AAA_SERVER_GROUP_DEADTIME
    assert_equal(deadtime, aaa_group.deadtime,
                 'Error: AaaServerGroup, deadtime not default')

    deadtime = 850
    create_deadtime(group_name, 'tacacs+', deadtime)
    assert_equal(deadtime, aaa_group.deadtime,
                 'Error: AaaServerGroup, deadtime not configured')

    deadtime = DEFAULT_AAA_SERVER_GROUP_DEADTIME
    aaa_group.deadtime = deadtime
    assert_equal(deadtime, aaa_group.deadtime,
                 'Error: AaaServerGroup, deadtime not restored to default')

    detach_aaaservergroup(aaa_group)
  end

  def test_get_deadtime_radius
    # TBD
  end

  def test_get_default_deadtime_tacacs
    aaa_group = AaaServerGroup.new('Group1', :tacacs)
    assert_equal(DEFAULT_AAA_SERVER_GROUP_DEADTIME,
                 AaaServerGroup.default_deadtime,
                 'Error: AaaServerGroup, default deadtime incorrect')
    detach_aaaservergroup(aaa_group)
  end

  def test_get_default_deadtime_radius
    # TBD
  end

  def test_set_deadtime_tacacs
    deadtime = 1250
    aaa_group = AaaServerGroup.new('Group1', :tacacs)
    aaa_group.deadtime = deadtime
    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /deadtime 1250/,
                      msg:     'Error: deadtime not configured')
    # Invalid case
    deadtime = 2450
    assert_raises(CliError) do
      aaa_group.deadtime = deadtime
    end
    detach_aaaservergroup(aaa_group)
  end

  def test_set_deadtime_radius
    # TBD
  end

  def test_get_source_interface_tacacs
    group_name = 'Group1'
    aaa_group = AaaServerGroup.new(group_name, :tacacs)
    intf = DEFAULT_AAA_SERVER_GROUP_SOURCE_INTERFACE
    assert_equal(intf, aaa_group.source_interface,
                 'Error: AaaServerGroup, source-interface set')

    intf = 'Ethernet1/1'
    create_source_interface(group_name, 'tacacs+', intf)
    assert_equal(intf, aaa_group.source_interface,
                 'Error: AaaServerGroup, source-interface not correct')

    intf = 'Ethernet1/32'
    create_source_interface(group_name, 'tacacs+', intf)
    assert_equal(intf, aaa_group.source_interface,
                 'Error: AaaServerGroup, source-interface not correct')

    detach_aaaservergroup(aaa_group)
  end

  def test_get_source_interface_radius
    # TBD
  end

  def test_get_default_source_interface_tacacs
    aaa_group = AaaServerGroup.new('Group1', :tacacs)
    assert_equal(DEFAULT_AAA_SERVER_GROUP_SOURCE_INTERFACE,
                 AaaServerGroup.default_source_interface,
                 'Error: Aaa_Group Server, default source-interface incorrect')
    detach_aaaservergroup(aaa_group)
  end

  def test_get_default_source_interface_radius
    # TBD
  end

  def test_set_source_interface_tacacs
    intf = DEFAULT_AAA_SERVER_GROUP_SOURCE_INTERFACE
    aaa_group = AaaServerGroup.new('Group1', :tacacs)
    assert_equal(intf, aaa_group.source_interface,
                 'Error: Aaa_Group Server, source-interface not default')

    aaa_group.source_interface = 'loopback1'
    assert_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /source-interface loopback1/,
                      msg:     'Error: source-interface not correct')

    aaa_group.source_interface = DEFAULT_AAA_SERVER_GROUP_SOURCE_INTERFACE
    refute_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /source-interface loopback1/)

    # Invalid case
    state = true
    assert_raises(TypeError) do
      aaa_group.source_interface = state
    end

    detach_aaaservergroup(aaa_group)
  end

  def test_set_source_interface_radius
    # TBD
  end

  def test_destroy_tacacs
    group_name = 'Group1'
    aaa_group = AaaServerGroup.new(group_name, :tacacs)

    detach_aaaservergroup(aaa_group)
    refute_show_match(command: 'show run tacacs+ all | no-more',
                      pattern: /Group1/)
  end

  def test_destroy_radius
    # TBD
  end
end
