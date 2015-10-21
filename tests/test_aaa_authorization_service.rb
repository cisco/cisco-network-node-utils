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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/aaa_authorization_service'

# TestAaaAuthorizationService - Minitest for AaaAuthorizationService util
# rubocop:disable ClassLength
class TestAaaAuthorizationService < CiscoTestCase
  # Method to pre-configure a valid tacacs server and aaa group.  This
  # group can be included in the testing such access to the device
  # never is compromised.
  def preconfig_tacacs_server_access(group_name, keep=true)
    @device.cmd('configure terminal')
    if keep
      @device.cmd('tacacs-server key testing123')
      @device.cmd('tacacs-server host 10.122.197.197 key testing123')
      @device.cmd("aaa group server tacacs+ #{group_name}")
      @device.cmd('server 10.122.197.197')
      @device.cmd('use-vrf management')
      @device.cmd('source-interface mgmt0')
      @device.cmd('aaa authentication login ascii-authentication')
    else
      @device.cmd("no aaa group server tacacs+ #{group_name}")
    end
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush
  end

  def feature_tacacs(feature=true)
    @device.cmd('configure terminal')
    if feature
      @device.cmd('feature tacacs')
    else
      @device.cmd('no feature tacacs')
      @device.cmd('no aaa authentication login ascii-authentication')
    end
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush
  end

  def config_tacacs_servers(servers)
    @device.cmd('configure terminal')
    @device.cmd('feature tacacs+')
    servers.each do |server|
      @device.cmd("aaa group server tacacs+ #{server}")
    end
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush
  end

  def get_match_line(name)
    s = @device.cmd('show run aaa all | no-more')
    prefix = 'aaa authorization'
    line = /#{prefix} #{name}/.match(s)
    line
  end

  def test_aaaauthorizationservice_create_unsupported_type
    assert_raises(ArgumentError) do
      AaaAuthorizationService.new(:none, 'default')
    end
  end

  def test_aaaauthorizationservice_create_nil_type
    assert_raises(TypeError) do
      AaaAuthorizationService.new(nil, 'default')
    end
  end

  def test_aaaauthorizationservice_create_invalid_type
    assert_raises(TypeError) do
      AaaAuthorizationService.new('test', 'default')
    end
  end

  def test_aaaauthorizationservice_create_invalid_range_type
    assert_raises(TypeError) do
      AaaAuthorizationService.new(34, 'default')
    end
  end

  def test_aaaauthorizationservice_create_invalid_service
    assert_raises(ArgumentError) do
      AaaAuthorizationService.new(:commands, 'test')
    end
  end

  def test_aaaauthorizationservice_create_empty_service
    assert_raises(ArgumentError) do
      AaaAuthorizationService.new(:commands, '')
    end
  end

  def test_aaaauthorizationservice_create_commands_default
    feature_tacacs
    aaa_a_service = AaaAuthorizationService.new(:commands, 'default')

    refute_nil(aaa_a_service,
               'Error: AaaAuthorizationService creating commands default')
    aaa_a_service.destroy unless aaa_a_service.nil?
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_create_commands_console
    feature_tacacs
    aaa_a_service = AaaAuthorizationService.new(:commands, 'console')

    refute_nil(aaa_a_service,
               'Error: AaaAuthorizationService creating commands default')
    aaa_a_service.destroy unless aaa_a_service.nil?
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_create_config_commands_default
    feature_tacacs
    aaa_a_service = AaaAuthorizationService.new(:config_commands, 'default')

    refute_nil(aaa_a_service,
               'Error: AaaAuthorizationService creating ' \
               'config-commands default')
    aaa_a_service.destroy unless aaa_a_service.nil?
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_create_config_commands_console
    feature_tacacs
    aaa_a_service = AaaAuthorizationService.new(:config_commands, 'console')

    refute_nil(aaa_a_service,
               'Error: AaaAuthorizationService creating commands default')
    aaa_a_service.destroy unless aaa_a_service.nil?
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_get_type
    feature_tacacs
    type = :config_commands
    aaa_a_service = AaaAuthorizationService.new(type, 'default')
    assert_equal(type, aaa_a_service.type, 'Error : Invalid type')
    aaa_a_service.destroy
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_get_name
    feature_tacacs
    service = 'default'
    aaa_a_service = AaaAuthorizationService.new(:config_commands, service)
    assert_equal(service, aaa_a_service.name, 'Error : Invalid service name')
    aaa_a_service.destroy
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_collection_invalid
    assert_nil(AaaAuthorizationService.services['TEST'])
  end

  def test_aaaauthorizationservice_collection_services_type_commands
    # Need feature tacacs for this test
    feature_tacacs
    type = :commands
    collection = AaaAuthorizationService.services[type]

    # Collection will not be empty since tacacs feature is enabled.
    refute_empty(collection,
                 'Error: AaaAuthorizationService collection is not filled')
    assert_equal(2, collection.size,
                 'Error:  AaaAuthorizationService collection not correct size')
    assert(collection.key?('default'),
           'Error:  AaaAuthorizationService collection does contain default')
    assert(collection.key?('console'),
           'Error: AaaAuthorizationService collection does contain console')

    collection.each do |service, aaa_a_service|
      assert_equal(service, aaa_a_service.name,
                   'Error: Invalid AaaAuthorizationService ' \
                   "#{service} in collection")

      method = :local
      assert_equal(method, aaa_a_service.method,
                   'Error: Invalid AaaAuthorizationService method for ' \
                   "#{service} in collection")

      groups = []
      assert_equal(groups, aaa_a_service.groups,
                   'Error: Invalid AaaAuthorizationService groups for ' \
                   "#{service} in collection")
      aaa_a_service.destroy
    end
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_collection_services_type_config_commands
    feature_tacacs
    type = :config_commands
    collection = AaaAuthorizationService.services[type]

    # Collection will not be empty since tacacs feature is enabled.
    refute_empty(collection,
                 'Error: AaaAuthorizationService collection is not filled')
    assert_equal(2, collection.size,
                 'Error:  AaaAuthorizationService collection not correct size')
    assert(collection.key?('default'),
           'Error:  AaaAuthorizationService collection does contain default')
    assert(collection.key?('console'),
           'Error: AaaAuthorizationService collection does contain console')

    collection.each do |service, aaa_a_service|
      assert_equal(service, aaa_a_service.name,
                   "Error: Invalid AaaAuthorizationService #{service} " \
                   'in collection')
      assert_equal(:local, aaa_a_service.method,
                   'Error: Invalid AaaAuthorizationService method for ' \
                   "#{service} in collection")

      # Due to preconfig groups will indeed be populated
      groups = []
      assert_equal(groups, aaa_a_service.groups,
                   'Error: Invalid AaaAuthorizationService groups for ' \
                   "#{service} in collection")
      aaa_a_service.destroy
    end
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_type_commands_default_console_group
    feature_tacacs

    # Preconfig AAA Authorization
    cmd1 = 'aaa authorization commands default group group2 group1 local'
    cmd2 = 'aaa authorization commands console group group1 local'
    @device.cmd('configure terminal')
    @device.cmd('aaa group server tacacs+ group1')
    @device.cmd('aaa group server tacacs+ group2')
    @device.cmd(cmd1)
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    type = :commands
    collection = AaaAuthorizationService.services[type]
    refute_empty(collection,
                 'Error: AaaAuthorizationService collection is not filled')
    assert_equal(2, collection.size,
                 'Error: AaaAuthorizationService collection not ' \
                 'reporting correct size')
    assert(collection.key?('default'),
           'Error: AaaAuthorizationService collection does contain default')
    assert(collection.key?('console'),
           'Error: AaaAuthorizationService collection does contain console')

    service = 'default'
    aaa_a_service = collection[service]

    assert_equal(service, aaa_a_service.name,
                 "Error: Invalid AaaAuthorizationService #{service} " \
                 'in collection')

    assert_equal(:local, aaa_a_service.method,
                 'Error: Invalid AaaAuthorizationService method for ' \
                 'default in collection')
    groups = %w(group2 group1)
    assert_equal(groups, aaa_a_service.groups,
                 'Error: Invalid AaaAuthorizationService groups for ' \
                 'default in collection')

    # only one of default or console can be configured at a time without
    # locking the CLI
    @device.cmd('configure terminal')
    @device.cmd("no #{cmd1}")
    @device.cmd(cmd2)
    @device.cmd('end')
    node.cache_flush

    service = 'console'
    aaa_a_service = collection[service]

    assert_equal(:local, aaa_a_service.method,
                 'Error: Invalid AaaAuthorizationService method for ' \
                 'console in collection')
    groups = ['group1']
    assert_equal(groups, aaa_a_service.groups,
                 'Error: Invalid AaaAuthorizationService groups for ' \
                 'console in collection')

    @device.cmd('configure terminal')
    @device.cmd("no #{cmd2}")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_type_config_commands_default_console_group
    feature_tacacs
    # Preconfig AAA Authorization
    cmd1 = 'aaa authorization config-commands default group group2 group1 local'
    cmd2 = 'aaa authorization config-commands console group group1 local'
    @device.cmd('configure terminal')
    @device.cmd('aaa group server tacacs+ group1')
    @device.cmd('aaa group server tacacs+ group2')
    @device.cmd(cmd1)
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    type = :config_commands
    collection = AaaAuthorizationService.services[type]
    refute_empty(collection,
                 'Error: AaaAuthorizationService collection is not filled')
    assert_equal(2, collection.size,
                 'Error: AaaAuthorizationService collection not ' \
                 'reporting correct size')
    assert(collection.key?('default'),
           'Error: AaaAuthorizationService collection does contain default')
    assert(collection.key?('console'),
           'Error: AaaAuthorizationService collection does contain console')

    service = 'default'
    aaa_a_service = collection[service]

    assert_equal(service, aaa_a_service.name,
                 "Error: Invalid AaaAuthorizationService #{service} " \
                 'in collection')

    assert_equal(:local, aaa_a_service.method,
                 'Error: Invalid AaaAuthorizationService method ' \
                 'for default in collection')
    groups = %w(group2 group1)
    assert_equal(groups, aaa_a_service.groups,
                 'Error: Invalid AaaAuthorizationService groups ' \
                 'for default in collection')

    @device.cmd('configure terminal')
    @device.cmd("no #{cmd1}")
    @device.cmd(cmd2)
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    service = 'console'
    aaa_a_service = collection[service]

    assert_equal(:local, aaa_a_service.method,
                 'Error: Invalid AaaAuthorizationService method ' \
                 'for console in collection')
    groups = ['group1']
    assert_equal(groups, aaa_a_service.groups,
                 'Error: Invalid AaaAuthorizationService groups ' \
                 'for console in collection')

    @device.cmd('configure terminal')
    @device.cmd("no #{cmd2}")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_get_default_method
    feature_tacacs
    type = :commands
    aaa_a_service = AaaAuthorizationService.new(type, 'default')
    assert_equal(:local, aaa_a_service.default_method,
                 'Error: AaaAuthorizationService command default, ' \
                 'default method')
    aaa_a_service.destroy

    aaa_a_service = AaaAuthorizationService.new(type, 'console')
    assert_equal(:local, aaa_a_service.default_method,
                 'Error: AaaAuthorizationService command console, ' \
                 'default method')
    aaa_a_service.destroy

    type = :config_commands
    aaa_a_service = AaaAuthorizationService.new(type, 'default')
    assert_equal(:local, aaa_a_service.default_method,
                 'Error: AaaAuthorizationService config-command ' \
                 'default, default method')
    aaa_a_service.destroy

    aaa_a_service = AaaAuthorizationService.new(type, 'console')
    assert_equal(:local, aaa_a_service.default_method,
                 'Error: AaaAuthorizationService config-command ' \
                 'console, default method')
    aaa_a_service.destroy
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_collection_groups_commands_default
    feature_tacacs

    type = :commands
    aaa_a_service = AaaAuthorizationService.new(type, 'default')

    # Default case
    assert_equal(aaa_a_service.default_groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService commands, ' \
                 'get groups for default')

    # Preconfigure tacacs, tacacs server and AAA valid group
    group0 = 'tac_group'
    preconfig_tacacs_server_access(group0)

    # Preconfig for test
    group1 = 'bxb100'
    group2 = 'sjc200'
    group3 = 'rtp10'
    servers = [group1, group2, group3]
    config_tacacs_servers(servers)

    @device.cmd('configure terminal')
    @device.cmd('aaa authorization commands default group ' \
                "#{group0} #{group1} #{group2}")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    groups = [group0, group1, group2]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService default get groups, 0/1/2')
    assert_equal(:unselected, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/1/2')

    # Change the config to have different groups and method
    @device.cmd('configure terminal')
    @device.cmd('aaa authorization commands default group ' \
                "#{group0} #{group3} #{group1} local")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    groups = [group0, group3, group1]
    # puts aaa_a_service.groups
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService default get groups, 0/3/1')
    assert_equal(:local, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/3/1')

    # Mix default and console, but since our instance is for 'default'
    # service we should only get 'default' groups and not 'console'
    # groups.
    aaa_cmd1 = 'aaa authorization commands default group ' \
               "#{group0} #{group2} #{group1} #{group3} local"
    aaa_cmd2 = 'aaa authorization commands console group ' \
               "#{group0} #{group2} #{group3} local"
    @device.cmd('configure terminal')
    @device.cmd(aaa_cmd1)
    @device.cmd(aaa_cmd2)
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    groups = [group0, group2, group1, group3]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService default get groups, 0/2/1/3')
    assert_equal(:local, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/3/1')

    # Cleanup
    aaa_a_service.destroy
    @device.cmd('configure terminal')
    @device.cmd("no #{aaa_cmd1}")
    @device.cmd("no #{aaa_cmd2}")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_collection_groups_commands_console
    feature_tacacs

    type = :commands
    aaa_a_service = AaaAuthorizationService.new(type, 'console')

    # Default case
    assert_equal(aaa_a_service.default_groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService commands, ' \
                 'get groups for console')

    # Preconfigure tacacs, tacacs server and AAA valid group
    group0 = 'tac_group'
    preconfig_tacacs_server_access(group0)

    # Preconfig for test
    group1 = 'bxb100'
    group2 = 'sjc200'
    group3 = 'rtp10'
    servers = [group1, group2, group3]
    config_tacacs_servers(servers)

    @device.cmd('configure terminal')
    @device.cmd('aaa authorization commands console group ' \
                "#{group0} #{group1} #{group2}")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    groups = [group0, group1, group2]
    # puts aaa_a_service.groups
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService console get groups, 0/1/2')
    assert_equal(:unselected, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/1/2')

    # Change the config to have different groups and method
    @device.cmd('configure terminal')
    @device.cmd('aaa authorization commands console group ' \
                "#{group0} #{group3} #{group1} local")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    groups = [group0, group3, group1]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService console get groups, 0/3/1')
    assert_equal(:local, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/3/1')

    # Mix default and console, but since our instance is for 'console'
    # service we should only get 'console' groups and not 'default'
    # groups.
    aaa_cmd1 = 'aaa authorization commands console group ' \
               "#{group0} #{group2} #{group1} #{group3} local"
    aaa_cmd2 = 'aaa authorization commands default group ' \
               "#{group0} #{group2} #{group3} local"
    @device.cmd('configure terminal')
    @device.cmd(aaa_cmd1)
    @device.cmd(aaa_cmd2)
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    groups = [group0, group2, group1, group3]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService console get groups, 0/2/1/3')
    assert_equal(:local, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/2/1/3')

    # Cleanup
    aaa_a_service.destroy
    @device.cmd('configure terminal')
    @device.cmd("no #{aaa_cmd1}")
    @device.cmd("no #{aaa_cmd2}")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_collection_groups_config_commands_default
    feature_tacacs

    type = :config_commands
    aaa_a_service = AaaAuthorizationService.new(type, 'default')

    # Default case
    assert_equal(aaa_a_service.default_groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService config-commands, ' \
                 'get groups for default')

    # Preconfigure tacacs, tacacs server and AAA valid group
    group0 = 'tac_group'
    preconfig_tacacs_server_access(group0)

    # Preconfig for test
    group1 = 'bxb100'
    group2 = 'sjc200'
    group3 = 'rtp10'
    servers = [group1, group2, group3]
    config_tacacs_servers(servers)

    @device.cmd('configure terminal')
    @device.cmd('aaa authorization config-commands default group ' \
                "#{group0} #{group1} #{group2}")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    groups = [group0, group1, group2]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService default get groups, 0/1/2')
    assert_equal(:unselected, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/1/2')

    # Change the config to have different groups and method
    @device.cmd('configure terminal')
    @device.cmd('aaa authorization config-commands default group ' \
                "#{group0} #{group3} #{group1} local")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    groups = [group0, group3, group1]
    # puts aaa_a_service.groups
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService default get groups, 0/3/1')
    assert_equal(:local, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/3/1')

    # Mix default and console, but since our instance is for 'default'
    # service we should only get 'default' groups and not 'console'
    # groups.
    aaa_cmd1 = 'aaa authorization config-commands default group ' \
               "#{group0} #{group2} #{group1} #{group3} local"
    aaa_cmd2 = 'aaa authorization config-commands console group ' \
               "#{group0} #{group2} #{group3} local"
    @device.cmd('configure terminal')
    @device.cmd(aaa_cmd1)
    @device.cmd(aaa_cmd2)
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    groups = [group0, group2, group1, group3]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService default get groups, 0/2/1/3')
    assert_equal(:local, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/2/1/3')

    # Cleanup
    aaa_a_service.destroy
    @device.cmd('configure terminal')
    @device.cmd("no #{aaa_cmd1}")
    @device.cmd("no #{aaa_cmd2}")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_collection_groups_config_commands_console
    feature_tacacs

    type = :config_commands
    aaa_a_service = AaaAuthorizationService.new(type, 'console')

    # Default case
    assert_equal(aaa_a_service.default_groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService config-commands, ' \
                 'get groups for console')

    # Preconfigure tacacs, tacacs server and AAA valid group
    group0 = 'tac_group'
    preconfig_tacacs_server_access(group0)

    # Preconfig for test
    group1 = 'bxb100'
    group2 = 'sjc200'
    group3 = 'rtp10'
    servers = [group1, group2, group3]
    config_tacacs_servers(servers)

    @device.cmd('configure terminal')
    @device.cmd('aaa authorization config-commands console group ' \
                "#{group0} #{group1} #{group2}")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    groups = [group0, group1, group2]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService console get groups, 0/1/2')
    assert_equal(:unselected, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/1/2')

    # Change the config to have different groups and method
    @device.cmd('configure terminal')
    @device.cmd('aaa authorization config-commands console group ' \
                "#{group0} #{group3} #{group1} local")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    groups = [group0, group3, group1]
    # puts aaa_a_service.groups
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService console get groups, 0/3/1')
    assert_equal(:local, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/3/1')

    # Mix default and console, but since our instance is for 'console'
    # service we should only get 'console' groups and not 'default'
    # groups.
    aaa_cmd1 = 'aaa authorization config-commands console group ' \
               "#{group0} #{group2} #{group1} #{group3} local"
    aaa_cmd2 = 'aaa authorization config-commands default group ' \
               "#{group0} #{group2} #{group3} local"
    @device.cmd('configure terminal')
    @device.cmd(aaa_cmd1)
    @device.cmd(aaa_cmd2)
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush

    groups = [group0, group2, group1, group3]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService console get groups, 0/2/1/3')
    assert_equal(:local, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/2/1/3')

    # Cleanup
    aaa_a_service.destroy
    @device.cmd('configure terminal')
    @device.cmd("no #{aaa_cmd1}")
    @device.cmd("no #{aaa_cmd2}")
    @device.cmd('end')
    # Flush the cache since we've modified the device outside of RLB
    node.cache_flush
    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_get_default_groups
    feature_tacacs
    groups = []

    type = :commands
    aaa_a_service = AaaAuthorizationService.new(type, 'default')

    assert_equal(groups, aaa_a_service.default_groups,
                 'Error: AaaAuthorizationService commands default, ' \
                 'default groups')
    aaa_a_service.destroy

    aaa_a_service = AaaAuthorizationService.new(type, 'console')

    assert_equal(groups, aaa_a_service.default_groups,
                 'Error: AaaAuthorizationService commands console, ' \
                 'default groups')
    aaa_a_service.destroy

    type = :config_commands
    aaa_a_service = AaaAuthorizationService.new(type, 'default')

    assert_equal(groups, aaa_a_service.default_groups,
                 'Error: AaaAuthorizationService config-commands ' \
                 'default, default groups')
    aaa_a_service.destroy

    aaa_a_service = AaaAuthorizationService.new(type, 'console')

    assert_equal(groups, aaa_a_service.default_groups,
                 'Error: AaaAuthorizationService config-commands ' \
                 'console, default groups')
    aaa_a_service.destroy

    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_commands_default_set_groups
    feature_tacacs

    # Preconfigure tacacs, tacacs server and AAA valid group
    group0 = 'tac_group'
    preconfig_tacacs_server_access(group0)

    # Preconfig for test
    group1 = 'bxb100'
    group2 = 'sjc200'
    group3 = 'rtp10'
    servers = [group1, group2, group3]
    config_tacacs_servers(servers)

    # Commands, service default
    type_str = 'commands'
    type = :commands
    service = 'default'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # Single group, with method 'unselected'
    method = :unselected
    groups = [group0]
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} group #{group0}"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationService #{type_str} #{service}, " \
               "set groups #{group0} #{method}")

    # Multi group, with method 'unselected'
    method = :unselected
    groups = [group0, group1, group2]
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} group #{group0} #{group1} #{group2}"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationService #{type_str} #{service}, " \
               "set groups #{group0}/#{group1}/#{group2} #{method}")

    # Multi group, with method 'local'
    method = :local
    groups = [group0, group1, group3]
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} group #{group0} #{group1} #{group3} local"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationService #{type_str} #{service}, " \
               "set groups #{group0}/#{group1}/#{group3} #{method}")

    # Default group and method
    method = aaa_a_service.default_method
    groups = aaa_a_service.default_groups
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} local"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationService #{type_str} #{service}, " \
               'set default groups and method')

    # Cleanup
    aaa_a_service.destroy

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_commands_console_set_groups
    feature_tacacs

    # Preconfigure tacacs, tacacs server and AAA valid group
    group0 = 'tac_group'
    preconfig_tacacs_server_access(group0)

    # Preconfig for test
    group1 = 'bxb100'
    group2 = 'sjc200'
    group3 = 'rtp10'
    servers = [group1, group2, group3]
    config_tacacs_servers(servers)

    # Commands, service console
    type_str = 'commands'
    type = :commands
    service = 'console'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # Single group, with method 'unselected'
    method = :unselected
    groups = [group0]
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} group #{group0}"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationService #{type_str} #{service}, " \
               "set groups #{group0} #{method}")

    # Multi group, with method 'unselected'
    method = :unselected
    groups = [group0, group1, group2]
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} group #{group0} #{group1} #{group2}"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationService #{type_str} #{service}, " \
               "set groups #{group0}/#{group1}/#{group2} #{method}")

    # Multi group, with method 'local'
    method = :local
    groups = [group0, group1, group3]
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} group #{group0} #{group1} #{group3} local"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationService #{type_str} #{service}, " \
               "set groups #{group0}/#{group1}/#{group3} #{method}")

    # Default group and method
    method = aaa_a_service.default_method
    groups = aaa_a_service.default_groups
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} local"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationservice #{type_str} #{service}, " \
               'set default groups and method')

    # Cleanup
    aaa_a_service.destroy

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_config_commands_default_set_groups
    feature_tacacs

    # Preconfigure tacacs, tacacs server and AAA valid group
    group0 = 'tac_group'
    preconfig_tacacs_server_access(group0)

    # Preconfig for test
    group1 = 'bxb100'
    group2 = 'sjc200'
    group3 = 'rtp10'
    servers = [group1, group2, group3]
    config_tacacs_servers(servers)

    # Commands, service default
    type_str = 'config-commands'
    type = :config_commands
    service = 'default'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # Single group, with method 'unselected'
    method = :unselected
    groups = [group0]
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} group #{group0}"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationService #{type_str} #{service}, " \
               "set groups #{group0} #{method}")

    # Multi group, with method 'unselected'
    method = :unselected
    groups = [group0, group1, group2]
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} group #{group0} #{group1} #{group2}"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationService #{type_str} #{service}, " \
               "set groups #{group0}/#{group1}/#{group2} #{method}")

    # Multi group, with method 'local'
    method = :local
    groups = [group0, group1, group3]
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} group #{group0} #{group1} #{group3} local"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationService #{type_str} #{service}, " \
               "set groups #{group0}/#{group1}/#{group3} #{method}")

    # Default group and method
    method = aaa_a_service.default_method
    groups = aaa_a_service.default_groups
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} local"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationService #{type_str} #{service}, " \
               'set default groups and method')

    # Cleanup
    aaa_a_service.destroy

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_config_commands_console_set_groups
    feature_tacacs

    # Preconfigure tacacs, tacacs server and AAA valid group
    group0 = 'tac_group'
    preconfig_tacacs_server_access(group0)

    # Preconfig for test
    group1 = 'bxb100'
    group2 = 'sjc200'
    group3 = 'rtp10'
    servers = [group1, group2, group3]
    config_tacacs_servers(servers)

    # Commands, service console
    type_str = 'config-commands'
    type = :config_commands
    service = 'console'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # Single group, with method 'unselected'
    method = :unselected
    groups = [group0]
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} group #{group0}"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationService #{type_str} #{service}, " \
               "set groups #{group0} #{method}")

    # Multi group, with method 'unselected'
    method = :unselected
    groups = [group0, group1, group2]
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} group #{group0} #{group1} #{group2}"
    line = get_match_line(match)
    refute_nil(line, "Error: AaaAuthorizationService #{type_str} #{service}, " \
      "set groups #{group0}/#{group1}/#{group2} #{method}")

    # Multi group, with method 'local'
    method = :local
    groups = [group0, group1, group3]
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} group #{group0} #{group1} #{group3} local"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationService #{type_str} #{service}, " \
               "set groups #{group0}/#{group1}/#{group3} #{method}")

    # Default group and method
    method = aaa_a_service.default_method
    groups = aaa_a_service.default_groups
    aaa_a_service.groups_method_set(groups, method)
    match = "#{type_str} #{service} local"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AaaAuthorizationservice #{type_str}  #{service}, " \
               'set default groups and method')

    # Cleanup
    aaa_a_service.destroy

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_commands_invalid_groups_method_set_groups
    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # Commands, with service default
    type = :commands
    service = 'default'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # Single invalid group
    groups = ['test1']
    assert_raises(RuntimeError) do
      aaa_a_service.groups_method_set(groups, :unselected)
    end

    # Multi groups with invalid group
    groups = %w(rtp10 test2 bxb100)
    assert_raises(RuntimeError) do
      aaa_a_service.groups_method_set(groups, :local)
    end
    aaa_a_service.destroy

    # Repeat the test for service 'console'
    service = 'console'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # Single invalid group
    groups = ['test1']
    assert_raises(RuntimeError) do
      aaa_a_service.groups_method_set(groups, :unselected)
    end

    # Multi group with invalid group
    groups = %w(rtp10 test1 bxb100)
    assert_raises(RuntimeError) do
      aaa_a_service.groups_method_set(groups, :local)
    end

    # Multiple group with group and invalid method
    groups = %w(rtp10 bxb100)
    assert_raises(TypeError) do
      aaa_a_service.groups_method_set(groups, 45)
    end

    aaa_a_service.destroy
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_config_commands_invalid_set_groups
    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # Commands, with service default
    type = :config_commands
    service = 'default'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # Single invalid group
    groups = ['test1']
    assert_raises(RuntimeError) do
      aaa_a_service.groups_method_set(groups, :unselected)
    end

    # Multi groups with invalid group
    groups = %w(rtp10 test2 bxb100)
    assert_raises(RuntimeError) do
      aaa_a_service.groups_method_set(groups, :local)
    end
    aaa_a_service.destroy

    # Repeat the test for service 'console'
    service = 'console'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # one invalid group
    groups = ['test1']
    assert_raises(RuntimeError) do
      aaa_a_service.groups_method_set(groups, :unselected)
    end

    # multiple group with invalid group
    groups = %w(rtp10 test1 bxb100)
    assert_raises(RuntimeError) do
      aaa_a_service.groups_method_set(groups, :local)
    end

    # Multiple group with group and invalid method
    groups = %w(rtp10 bxb100)
    assert_raises(TypeError) do
      aaa_a_service.groups_method_set(groups, 45)
    end

    aaa_a_service.destroy
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_commands_invalid_method
    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # Commands, with service default
    type = :commands
    service = 'default'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # No group and invalid method
    groups = []
    assert_raises(TypeError) do
      aaa_a_service.groups_method_set(groups, 'test')
    end

    # Multiple group with group and invalid method
    groups = %w(rtp10 bxb100)
    assert_raises(TypeError) do
      aaa_a_service.groups_method_set(groups, 45)
    end
    aaa_a_service.destroy

    # Repeat the test for service 'console'
    service = 'console'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # No group and invalid method
    groups = []
    assert_raises(TypeError) do
      aaa_a_service.groups_method_set(groups, 'test')
    end

    # Multiple group with group and invalid method
    groups = %w(rtp10 bxb100)
    assert_raises(TypeError) do
      aaa_a_service.groups_method_set(groups, 45)
    end

    aaa_a_service.destroy
    feature_tacacs(false)
  end

  def test_aaaauthorizationservice_config_commands_invalid_method
    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # Commands, with service default
    type = :config_commands
    service = 'default'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # No group and invalid method
    groups = []
    assert_raises(TypeError) do
      aaa_a_service.groups_method_set(groups, 'test')
    end

    # Multiple group with group and invalid method
    groups = %w(rtp10 bxb100)
    assert_raises(TypeError) do
      aaa_a_service.groups_method_set(groups, 45)
    end
    aaa_a_service.destroy

    # Repeat the test for service 'console'
    service = 'console'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # No group and invalid method
    groups = []
    assert_raises(TypeError) do
      aaa_a_service.groups_method_set(groups, 'test')
    end

    # Multiple group with group and invalid method
    groups = %w(rtp10 bxb100)
    assert_raises(TypeError) do
      aaa_a_service.groups_method_set(groups, 45)
    end

    aaa_a_service.destroy
    feature_tacacs(false)
  end
end
