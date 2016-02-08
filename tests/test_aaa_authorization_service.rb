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
require_relative '../lib/cisco_node_utils/aaa_authorization_service'

# TestAaaAuthorizationService - Minitest for AaaAuthorizationService util
class TestAaaAuthorizationService < CiscoTestCase
  def setup
    super
    feature_tacacs
  end

  def teardown
    feature_tacacs(false)
    super
  end

  # Method to pre-configure a valid tacacs server and aaa group.  This
  # group can be included in the testing such access to the device
  # never is compromised.
  def preconfig_tacacs_server_access(group_name, keep=true)
    if keep
      config('tacacs-server key testing123',
             'tacacs-server host 10.122.197.197 key testing123',
             "aaa group server tacacs+ #{group_name}",
             'server 10.122.197.197',
             'use-vrf management',
             'source-interface mgmt0',
             'aaa authentication login ascii-authentication')
    else
      config("no aaa group server tacacs+ #{group_name}")
    end
  end

  def feature_tacacs(feature=true)
    if feature
      config('feature tacacs')
    else
      config('no feature tacacs',
             'no aaa authentication login ascii-authentication')
    end
  end

  def config_tacacs_servers(servers)
    config('feature tacacs+')
    servers.each do |server|
      config("aaa group server tacacs+ #{server}")
    end
  end

  def show_cmd
    'show run aaa all | no-more'
  end

  def prefix
    'aaa authorization'
  end

  def test_create_unsupported_type
    assert_raises(ArgumentError) do
      AaaAuthorizationService.new(:none, 'default')
    end
  end

  def test_create_nil_type
    assert_raises(TypeError) do
      AaaAuthorizationService.new(nil, 'default')
    end
  end

  def test_create_invalid_type
    assert_raises(TypeError) do
      AaaAuthorizationService.new('test', 'default')
    end
  end

  def test_create_invalid_range_type
    assert_raises(TypeError) do
      AaaAuthorizationService.new(34, 'default')
    end
  end

  def test_create_invalid_service
    assert_raises(ArgumentError) do
      AaaAuthorizationService.new(:commands, 'test')
    end
  end

  def test_create_empty_service
    assert_raises(ArgumentError) do
      AaaAuthorizationService.new(:commands, '')
    end
  end

  def test_create_commands_default
    aaa_a_service = AaaAuthorizationService.new(:commands, 'default')
    refute_nil(aaa_a_service,
               'Error: AaaAuthorizationService creating commands default')
    aaa_a_service.destroy unless aaa_a_service.nil?
  end

  def test_create_commands_console
    aaa_a_service = AaaAuthorizationService.new(:commands, 'console')
    refute_nil(aaa_a_service,
               'Error: AaaAuthorizationService creating commands default')
    aaa_a_service.destroy unless aaa_a_service.nil?
  end

  def test_create_config_commands_default
    aaa_a_service = AaaAuthorizationService.new(:config_commands, 'default')
    refute_nil(aaa_a_service,
               'Error: AaaAuthorizationService creating ' \
               'config-commands default')
    aaa_a_service.destroy unless aaa_a_service.nil?
  end

  def test_create_config_commands_console
    aaa_a_service = AaaAuthorizationService.new(:config_commands, 'console')
    refute_nil(aaa_a_service,
               'Error: AaaAuthorizationService creating commands default')
    aaa_a_service.destroy unless aaa_a_service.nil?
  end

  def test_get_type
    type = :config_commands
    aaa_a_service = AaaAuthorizationService.new(type, 'default')
    assert_equal(type, aaa_a_service.type, 'Error : Invalid type')
    aaa_a_service.destroy
  end

  def test_get_name
    service = 'default'
    aaa_a_service = AaaAuthorizationService.new(:config_commands, service)
    assert_equal(service, aaa_a_service.name, 'Error : Invalid service name')
    aaa_a_service.destroy
  end

  def test_collection_invalid
    assert_nil(AaaAuthorizationService.services['TEST'])
  end

  def test_collection_services_type_commands
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
  end

  def test_collection_services_type_config_commands
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
  end

  def test_type_commands_default_console_group
    # Preconfig AAA Authorization
    cmd1 = 'aaa authorization commands default group group2 group1 local'
    cmd2 = 'aaa authorization commands console group group1 local'
    config('aaa group server tacacs+ group1',
           'aaa group server tacacs+ group2',
           cmd1)

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
    config("no #{cmd1}", cmd2)

    service = 'console'
    aaa_a_service = collection[service]

    assert_equal(:local, aaa_a_service.method,
                 'Error: Invalid AaaAuthorizationService method for ' \
                 'console in collection')
    groups = ['group1']
    assert_equal(groups, aaa_a_service.groups,
                 'Error: Invalid AaaAuthorizationService groups for ' \
                 'console in collection')

    config("no #{cmd2}")
  end

  def test_type_config_commands_default_console_group
    # Preconfig AAA Authorization
    cmd1 = 'aaa authorization config-commands default group group2 group1 local'
    cmd2 = 'aaa authorization config-commands console group group1 local'
    config('aaa group server tacacs+ group1',
           'aaa group server tacacs+ group2',
           cmd1)

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

    config("no #{cmd1}", cmd2)

    service = 'console'
    aaa_a_service = collection[service]

    assert_equal(:local, aaa_a_service.method,
                 'Error: Invalid AaaAuthorizationService method ' \
                 'for console in collection')
    groups = ['group1']
    assert_equal(groups, aaa_a_service.groups,
                 'Error: Invalid AaaAuthorizationService groups ' \
                 'for console in collection')

    config("no #{cmd2}")
  end

  def test_get_default_method
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
  end

  def test_collection_groups_commands_default
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

    config('aaa authorization commands default group ' \
           "#{group0} #{group1} #{group2}")

    groups = [group0, group1, group2]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService default get groups, 0/1/2')
    assert_equal(:unselected, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/1/2')

    # Change the config to have different groups and method
    config('aaa authorization commands default group ' \
           "#{group0} #{group3} #{group1} local")

    groups = [group0, group3, group1]
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
    config(aaa_cmd1, aaa_cmd2)

    groups = [group0, group2, group1, group3]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService default get groups, 0/2/1/3')
    assert_equal(:local, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/3/1')

    # Cleanup
    aaa_a_service.destroy
    config("no #{aaa_cmd1}", "no #{aaa_cmd2}")

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
  end

  def test_collection_groups_commands_console
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

    config('aaa authorization commands console group ' \
           "#{group0} #{group1} #{group2}")

    groups = [group0, group1, group2]
    # puts aaa_a_service.groups
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService console get groups, 0/1/2')
    assert_equal(:unselected, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/1/2')

    # Change the config to have different groups and method
    config('aaa authorization commands console group ' \
           "#{group0} #{group3} #{group1} local")

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
    config(aaa_cmd1, aaa_cmd2)

    groups = [group0, group2, group1, group3]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService console get groups, 0/2/1/3')
    assert_equal(:local, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/2/1/3')

    # Cleanup
    aaa_a_service.destroy
    config("no #{aaa_cmd1}", "no #{aaa_cmd2}")

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
  end

  def test_collection_groups_config_commands_default
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

    config('aaa authorization config-commands default group ' \
           "#{group0} #{group1} #{group2}")

    groups = [group0, group1, group2]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService default get groups, 0/1/2')
    assert_equal(:unselected, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/1/2')

    # Change the config to have different groups and method
    config('aaa authorization config-commands default group ' \
           "#{group0} #{group3} #{group1} local")

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
    config(aaa_cmd1, aaa_cmd2)

    groups = [group0, group2, group1, group3]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService default get groups, 0/2/1/3')
    assert_equal(:local, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/2/1/3')

    # Cleanup
    aaa_a_service.destroy
    config("no #{aaa_cmd1}", "no #{aaa_cmd2}")

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
  end

  def test_collection_groups_config_commands_console
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

    config('aaa authorization config-commands console group ' \
           "#{group0} #{group1} #{group2}")

    groups = [group0, group1, group2]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService console get groups, 0/1/2')
    assert_equal(:unselected, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/1/2')

    # Change the config to have different groups and method
    config('aaa authorization config-commands console group ' \
           "#{group0} #{group3} #{group1} local")

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
    config(aaa_cmd1, aaa_cmd2)

    groups = [group0, group2, group1, group3]
    assert_equal(groups, aaa_a_service.groups,
                 'Error: AaaAuthorizationService console get groups, 0/2/1/3')
    assert_equal(:local, aaa_a_service.method,
                 'Error: AaaAuthorizationService default get method, 0/2/1/3')

    # Cleanup
    aaa_a_service.destroy
    config("no #{aaa_cmd1}", "no #{aaa_cmd2}")

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
  end

  def test_get_default_groups
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
  end

  def test_commands_default_set_groups
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

    p = /#{prefix} #{type_str} #{service} group #{group0}/
    assert_show_match(command: show_cmd, pattern: p)

    # Multi group, with method 'unselected'
    method = :unselected
    groups = [group0, group1, group2]
    aaa_a_service.groups_method_set(groups, method)

    p = /#{prefix} #{type_str} #{service} group #{group0} #{group1} #{group2}/
    assert_show_match(command: show_cmd, pattern: p)

    # Multi group, with method 'local'
    method = :local
    groups = [group0, group1, group3]
    aaa_a_service.groups_method_set(groups, method)

    group_str = "group #{group0} #{group1} #{group3}"
    p = /#{prefix} #{type_str} #{service} #{group_str} local/
    assert_show_match(command: show_cmd, pattern: p)

    # Default group and method
    method = aaa_a_service.default_method
    groups = aaa_a_service.default_groups
    aaa_a_service.groups_method_set(groups, method)

    p = /#{prefix} #{type_str} #{service} local/
    assert_show_match(command: show_cmd, pattern: p)

    # Cleanup
    aaa_a_service.destroy

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
  end

  def test_commands_console_set_groups
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

    p = /#{prefix} #{type_str} #{service} group #{group0}/
    assert_show_match(command: show_cmd, pattern: p)

    # Multi group, with method 'unselected'
    method = :unselected
    groups = [group0, group1, group2]
    aaa_a_service.groups_method_set(groups, method)

    p = /#{prefix} #{type_str} #{service} group #{group0} #{group1} #{group2}/
    assert_show_match(command: show_cmd, pattern: p)

    # Multi group, with method 'local'
    method = :local
    groups = [group0, group1, group3]
    aaa_a_service.groups_method_set(groups, method)

    group_str = "group #{group0} #{group1} #{group3}"
    p = /#{prefix} #{type_str} #{service} #{group_str} local/
    assert_show_match(command: show_cmd, pattern: p)

    # Default group and method
    method = aaa_a_service.default_method
    groups = aaa_a_service.default_groups
    aaa_a_service.groups_method_set(groups, method)

    p = /#{prefix} #{type_str} #{service} local/
    assert_show_match(command: show_cmd, pattern: p)

    aaa_a_service.destroy

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
  end

  def test_config_commands_default_set_groups
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

    p = /#{prefix} #{type_str} #{service} group #{group0}/
    assert_show_match(command: show_cmd, pattern: p)

    # Multi group, with method 'unselected'
    method = :unselected
    groups = [group0, group1, group2]
    aaa_a_service.groups_method_set(groups, method)

    p = /#{prefix} #{type_str} #{service} group #{group0} #{group1} #{group2}/
    assert_show_match(command: show_cmd, pattern: p)

    # Multi group, with method 'local'
    method = :local
    groups = [group0, group1, group3]
    aaa_a_service.groups_method_set(groups, method)

    group_str = "group #{group0} #{group1} #{group3}"
    p = /#{prefix} #{type_str} #{service} #{group_str} local/
    assert_show_match(command: show_cmd, pattern: p)

    # Default group and method
    method = aaa_a_service.default_method
    groups = aaa_a_service.default_groups
    aaa_a_service.groups_method_set(groups, method)

    p = /#{prefix} #{type_str} #{service} local/
    assert_show_match(command: show_cmd, pattern: p)

    aaa_a_service.destroy

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
  end

  def test_config_commands_console_set_groups
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

    p = /#{prefix} #{type_str} #{service} group #{group0}/
    assert_show_match(command: show_cmd, pattern: p)

    # Multi group, with method 'unselected'
    method = :unselected
    groups = [group0, group1, group2]
    aaa_a_service.groups_method_set(groups, method)

    p = /#{prefix} #{type_str} #{service} group #{group0} #{group1} #{group2}/
    assert_show_match(command: show_cmd, pattern: p)

    # Multi group, with method 'local'
    method = :local
    groups = [group0, group1, group3]
    aaa_a_service.groups_method_set(groups, method)

    group_str = "group #{group0} #{group1} #{group3}"
    p = /#{prefix} #{type_str} #{service} #{group_str} local/
    assert_show_match(command: show_cmd, pattern: p)

    # Default group and method
    method = aaa_a_service.default_method
    groups = aaa_a_service.default_groups
    aaa_a_service.groups_method_set(groups, method)

    p = /#{prefix} #{type_str} #{service} local/
    assert_show_match(command: show_cmd, pattern: p)

    aaa_a_service.destroy

    # Unconfigure tacacs, tacacs server and AAA valid group
    preconfig_tacacs_server_access(group0, false)
  end

  def test_commands_invalid_groups_method_set_groups
    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # Commands, with service default
    type = :commands
    service = 'default'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # Single invalid group
    groups = ['test1']
    assert_raises(Cisco::CliError) do
      aaa_a_service.groups_method_set(groups, :unselected)
    end

    # Multi groups with invalid group
    groups = %w(rtp10 test2 bxb100)
    assert_raises(Cisco::CliError) do
      aaa_a_service.groups_method_set(groups, :local)
    end
    aaa_a_service.destroy

    # Repeat the test for service 'console'
    service = 'console'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # Single invalid group
    groups = ['test1']
    assert_raises(Cisco::CliError) do
      aaa_a_service.groups_method_set(groups, :unselected)
    end

    # Multi group with invalid group
    groups = %w(rtp10 test1 bxb100)
    assert_raises(Cisco::CliError) do
      aaa_a_service.groups_method_set(groups, :local)
    end

    # Multiple group with group and invalid method
    groups = %w(rtp10 bxb100)
    assert_raises(TypeError) do
      aaa_a_service.groups_method_set(groups, 45)
    end

    aaa_a_service.destroy
  end

  def test_config_commands_invalid_set_groups
    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # Commands, with service default
    type = :config_commands
    service = 'default'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # Single invalid group
    groups = ['test1']
    assert_raises(Cisco::CliError) do
      aaa_a_service.groups_method_set(groups, :unselected)
    end

    # Multi groups with invalid group
    groups = %w(rtp10 test2 bxb100)
    assert_raises(Cisco::CliError) do
      aaa_a_service.groups_method_set(groups, :local)
    end
    aaa_a_service.destroy

    # Repeat the test for service 'console'
    service = 'console'
    aaa_a_service = AaaAuthorizationService.new(type, service)

    # one invalid group
    groups = ['test1']
    assert_raises(Cisco::CliError) do
      aaa_a_service.groups_method_set(groups, :unselected)
    end

    # multiple group with invalid group
    groups = %w(rtp10 test1 bxb100)
    assert_raises(Cisco::CliError) do
      aaa_a_service.groups_method_set(groups, :local)
    end

    # Multiple group with group and invalid method
    groups = %w(rtp10 bxb100)
    assert_raises(TypeError) do
      aaa_a_service.groups_method_set(groups, 45)
    end

    aaa_a_service.destroy
  end

  def test_commands_invalid_method
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
  end

  def test_config_commands_invalid_method
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
  end
end
