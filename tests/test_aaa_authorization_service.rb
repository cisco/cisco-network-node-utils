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

require 'yaml'
require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/aaa_authorization_service'

# TestAaaAuthorizationService - Minitest for AaaAuthorizationService util
class TestAaaAuthorizationService < CiscoTestCase
  @skip_unless_supported = 'aaa_authorization_service'
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super

    cleanup_aaa if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
    feature_tacacs
    preconfig_tacacs_server_access(tacacs_groups[0])
    config_tacacs_servers(tacacs_groups[1..3])
  end

  def teardown
    cleanup_aaa
    feature_tacacs(false)
    super
  end

  def cleanup_aaa
    cmds = config('show run aaa').scan(/^aaa auth.*/)
    cmds.each do |cmd|
      config("no #{cmd}")
    end
  end

  def config_tacacs_servers(servers)
    servers.each do |server|
      config("aaa group server tacacs+ #{server}")
    end
  end

  def feature_tacacs(feature=true)
    state = feature ? '' : 'no'
    config("#{state} feature tacacs+")
  end

  # Helper method to get regexp for aaa authorization commands
  def get_pattern(cmd_type, service, groups, method=:unselected)
    cmd_type = cmd_type == :config_commands ? 'config-commands' : cmd_type.to_s
    groups = groups.join(' ') if groups.is_a? Array
    method = method == :unselected ? '' : method.to_s
    p = prefix
    p << ' ' + cmd_type
    p << ' ' + service
    p << ' group ' + groups unless groups.empty?
    p << ' ' + method unless method.empty?
    Regexp.new(p)
  end

  # Pre-configure the user-defined tacacs server in tests/tacacs_server.yaml
  def preconfig_tacacs_server_access(group_name)
    path = File.expand_path('../tacacs_server.yaml', __FILE__)
    skip('Cannot find tests/tacacs_server.yaml') unless File.file?(path)
    cfg = YAML.load(File.read(path))
    valid_cfg?(cfg)
    config("tacacs-server host #{cfg['host']} key #{cfg['key']}",
           "aaa group server tacacs+ #{group_name}",
           "server #{cfg['host']}",
           "use-vrf #{cfg['vrf']}",
           "source-interface #{cfg['intf']}",
           'aaa authentication login ascii-authentication')
    valid_server?(cfg['host'])
  end

  def prefix
    'aaa authorization'
  end

  def show_cmd
    'show run aaa all | no-more'
  end

  def tacacs_groups
    %w(tac_group bxb100 sjc200 rtp10)
  end

  def valid_cfg?(cfg)
    skip('tests/tacacs_server.yaml file is empty') unless cfg
    msg = 'Missing key in tests/tacacs_server.yaml'
    %w(host key vrf intf).each do |key|
      skip("#{msg}: #{key}") if cfg[key].nil?
    end
  end

  def valid_server?(host)
    test_aaa = config("test aaa server tacacs+ #{host} test test")
    # Valid tacacs server will return message regarding user authentication
    valid = test_aaa[/^user has \S+ authenticat(ed|ion)/]
    fail "Host '#{host}' is either not a valid tacacs server " \
          'or not reachable' unless valid
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

    # AAA authorization method 'local' is a prerequisite for this test but
    # once configured by design is not allowed to be removed.  Remove 'local'
    # from cmd1 and cmd2 for cleanup.
    remove1 = cmd1.gsub('local', '')
    remove2 = cmd2.gsub('local', '')

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
    config("no #{remove1}", cmd2)

    service = 'console'
    aaa_a_service = collection[service]

    assert_equal(:local, aaa_a_service.method,
                 'Error: Invalid AaaAuthorizationService method for ' \
                 'console in collection')
    groups = ['group1']
    assert_equal(groups, aaa_a_service.groups,
                 'Error: Invalid AaaAuthorizationService groups for ' \
                 'console in collection')

    config("no #{remove2}")
  end

  def test_type_config_commands_default_console_group
    # Preconfig AAA Authorization
    cmd1 = 'aaa authorization config-commands default group group2 group1 local'
    cmd2 = 'aaa authorization config-commands console group group1 local'
    config('aaa group server tacacs+ group1',
           'aaa group server tacacs+ group2',
           cmd1)

    # AAA authorization method 'local' is a prerequisite for this test but
    # once configured by design is not allowed to be removed.  Remove 'local'
    # from cmd1 and cmd2 for cleanup.
    remove1 = cmd1.gsub('local', '')
    remove2 = cmd2.gsub('local', '')

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

    config("no #{remove1}", cmd2)

    service = 'console'
    aaa_a_service = collection[service]

    assert_equal(:local, aaa_a_service.method,
                 'Error: Invalid AaaAuthorizationService method ' \
                 'for console in collection')
    groups = ['group1']
    assert_equal(groups, aaa_a_service.groups,
                 'Error: Invalid AaaAuthorizationService groups ' \
                 'for console in collection')

    config("no #{remove2}")
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

    config('aaa authorization commands default group ' \
           "#{tacacs_groups[0..2].join(' ')}")

    assert_equal(tacacs_groups[0..2], aaa_a_service.groups)
    assert_equal(:unselected, aaa_a_service.method)

    # Change the config to have different groups and method
    config('aaa authorization commands default group ' \
           "#{tacacs_groups[0]} #{tacacs_groups[3]} #{tacacs_groups[1]} local")

    conf_groups = [tacacs_groups[0], tacacs_groups[3], tacacs_groups[1]]
    assert_equal(conf_groups, aaa_a_service.groups)
    assert_equal(:local, aaa_a_service.method)

    # Mix default and console, but since our instance is for 'default'
    # service we should only get 'default' groups and not 'console'
    # groups.
    aaa_cmd1 = 'aaa authorization commands default group ' \
               "#{tacacs_groups.join(' ')} local"
    aaa_cmd2 = 'aaa authorization commands console group ' \
               "#{tacacs_groups[1..3].join(' ')} local"
    config(aaa_cmd1, aaa_cmd2)

    assert_equal(tacacs_groups, aaa_a_service.groups)
    assert_equal(:local, aaa_a_service.method)
  end

  def test_collection_groups_commands_console
    type = :commands
    aaa_a_service = AaaAuthorizationService.new(type, 'console')

    # Default case
    assert_equal(aaa_a_service.default_groups, aaa_a_service.groups)

    config('aaa authorization commands console group ' \
           "#{tacacs_groups[0..2].join(' ')}")

    assert_equal(tacacs_groups[0..2], aaa_a_service.groups)
    assert_equal(:unselected, aaa_a_service.method)

    # Change the config to have different groups and method
    config('aaa authorization commands console group ' \
           "#{tacacs_groups[0]} #{tacacs_groups[3]} #{tacacs_groups[1]} local")

    conf_groups = [tacacs_groups[0], tacacs_groups[3], tacacs_groups[1]]
    assert_equal(conf_groups, aaa_a_service.groups)
    assert_equal(:local, aaa_a_service.method)

    # Mix default and console, but since our instance is for 'console'
    # service we should only get 'console' groups and not 'default'
    # groups.
    aaa_cmd1 = 'aaa authorization commands console group ' \
               "#{tacacs_groups.join(' ')} local"
    aaa_cmd2 = 'aaa authorization commands default group ' \
               "#{tacacs_groups[1..3].join(' ')} local"
    config(aaa_cmd1, aaa_cmd2)

    assert_equal(tacacs_groups, aaa_a_service.groups)
    assert_equal(:local, aaa_a_service.method)
  end

  def test_collection_groups_config_commands_default
    type = :config_commands
    aaa_a_service = AaaAuthorizationService.new(type, 'default')

    # Default case
    assert_equal(aaa_a_service.default_groups, aaa_a_service.groups)

    config('aaa authorization config-commands default group ' \
           "#{tacacs_groups[0]} #{tacacs_groups[1]} #{tacacs_groups[2]}")

    assert_equal(tacacs_groups[0..2], aaa_a_service.groups)
    assert_equal(:unselected, aaa_a_service.method)

    # Change the config to have different groups and method
    config('aaa authorization config-commands default group ' \
           "#{tacacs_groups[0]} #{tacacs_groups[3]} #{tacacs_groups[1]} local")

    conf_groups = [tacacs_groups[0], tacacs_groups[3], tacacs_groups[1]]
    assert_equal(conf_groups, aaa_a_service.groups)
    assert_equal(:local, aaa_a_service.method)

    # Mix default and console, but since our instance is for 'default'
    # service we should only get 'default' groups and not 'console'
    # groups.
    aaa_cmd1 = 'aaa authorization config-commands default group ' \
               "#{tacacs_groups.join(' ')} local"
    aaa_cmd2 = 'aaa authorization config-commands console group ' \
               "#{tacacs_groups[1..3].join(' ')} local"
    config(aaa_cmd1, aaa_cmd2)

    assert_equal(tacacs_groups, aaa_a_service.groups)
    assert_equal(:local, aaa_a_service.method)
  end

  def test_collection_groups_config_commands_console
    type = :config_commands
    aaa_a_service = AaaAuthorizationService.new(type, 'console')

    # Default case
    assert_equal(aaa_a_service.default_groups, aaa_a_service.groups)

    config('aaa authorization config-commands console group ' \
           "#{tacacs_groups[0..2].join(' ')}")

    assert_equal(tacacs_groups[0..2], aaa_a_service.groups)
    assert_equal(:unselected, aaa_a_service.method)

    # Change the config to have different groups and method
    config('aaa authorization config-commands console group ' \
           "#{tacacs_groups[0]} #{tacacs_groups[3]} #{tacacs_groups[1]} local")

    conf_groups = [tacacs_groups[0], tacacs_groups[3], tacacs_groups[1]]
    assert_equal(conf_groups, aaa_a_service.groups)
    assert_equal(:local, aaa_a_service.method)

    # Mix default and console, but since our instance is for 'console'
    # service we should only get 'console' groups and not 'default'
    # groups.
    aaa_cmd1 = 'aaa authorization config-commands console group ' \
               "#{tacacs_groups.join(' ')} local"
    aaa_cmd2 = 'aaa authorization config-commands default group ' \
               "#{tacacs_groups[1..3].join(' ')} local"
    config(aaa_cmd1, aaa_cmd2)

    assert_equal(tacacs_groups, aaa_a_service.groups)
    assert_equal(:local, aaa_a_service.method)
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

  def test_commands_default_unselected_single
    aaa_a_service = AaaAuthorizationService.new(:commands, 'default')
    aaa_a_service.groups_method_set(tacacs_groups[0], :unselected)

    p = get_pattern(:commands, 'default', tacacs_groups[0])
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_commands_default_unselected_multi
    aaa_a_service = AaaAuthorizationService.new(:commands, 'default')
    aaa_a_service.groups_method_set(tacacs_groups[0..2], :unselected)

    p = get_pattern(:commands, 'default', tacacs_groups[0..2])
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_commands_default_local_multi
    aaa_a_service = AaaAuthorizationService.new(:commands, 'default')
    aaa_a_service.groups_method_set(tacacs_groups[0..2], :local)

    p = get_pattern(:commands, 'default', tacacs_groups[0..2], :local)
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_commands_default_all_default
    aaa_a_service = AaaAuthorizationService.new(:commands, 'default')
    method = aaa_a_service.default_method
    groups = aaa_a_service.default_groups
    aaa_a_service.groups_method_set(groups, method)

    p = get_pattern(:commands, 'default', groups, method)
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_commands_console_unselected_single
    aaa_a_service = AaaAuthorizationService.new(:commands, 'console')
    aaa_a_service.groups_method_set(tacacs_groups[0], :unselected)

    p = get_pattern(:commands, 'console', tacacs_groups[0])
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_commands_console_unselected_multi
    aaa_a_service = AaaAuthorizationService.new(:commands, 'console')
    aaa_a_service.groups_method_set(tacacs_groups[0..2], :unselected)

    p = get_pattern(:commands, 'console', tacacs_groups[0..2])
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_commands_console_local_multi
    aaa_a_service = AaaAuthorizationService.new(:commands, 'console')
    aaa_a_service.groups_method_set(tacacs_groups[0..2], :local)

    p = get_pattern(:commands, 'console', tacacs_groups[0..2], :local)
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_commans_console_all_default
    aaa_a_service = AaaAuthorizationService.new(:commands, 'console')
    method = aaa_a_service.default_method
    groups = aaa_a_service.default_groups
    aaa_a_service.groups_method_set(groups, method)

    p = get_pattern(:commands, 'console', groups, method)
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_config_commands_default_unselected_single
    aaa_a_service = AaaAuthorizationService.new(:config_commands, 'default')
    aaa_a_service.groups_method_set(tacacs_groups[0], :unselected)

    p = get_pattern(:config_commands, 'default', tacacs_groups[0])
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_config_commands_default_unselected_multi
    aaa_a_service = AaaAuthorizationService.new(:config_commands, 'default')
    aaa_a_service.groups_method_set(tacacs_groups[0..2], :unselected)

    p = get_pattern(:config_commands, 'default', tacacs_groups[0..2])
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_config_commands_default_local_multi
    aaa_a_service = AaaAuthorizationService.new(:config_commands, 'default')
    aaa_a_service.groups_method_set(tacacs_groups[0..2], :local)

    p = get_pattern(:config_commands, 'default', tacacs_groups[0..2], :local)
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_config_commands_default_all_default
    aaa_a_service = AaaAuthorizationService.new(:config_commands, 'default')

    method = aaa_a_service.default_method
    groups = aaa_a_service.default_groups
    aaa_a_service.groups_method_set(groups, method)

    p = get_pattern(:config_commands, 'default', groups, method)
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_config_commands_console_unselected_single
    aaa_a_service = AaaAuthorizationService.new(:config_commands, 'console')
    aaa_a_service.groups_method_set(tacacs_groups[0], :unselected)

    p = get_pattern(:config_commands, 'console', tacacs_groups[0])
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_config_commands_console_unselected_multi
    aaa_a_service = AaaAuthorizationService.new(:config_commands, 'console')
    aaa_a_service.groups_method_set(tacacs_groups[0..2], :unselected)

    p = get_pattern(:config_commands, 'console', tacacs_groups[0..2])
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_config_commands_console_local_multi
    aaa_a_service = AaaAuthorizationService.new(:config_commands, 'console')
    aaa_a_service.groups_method_set(tacacs_groups[0..2], :local)

    p = get_pattern(:config_commands, 'console', tacacs_groups[0..2], :local)
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_config_commands_console_all_default
    aaa_a_service = AaaAuthorizationService.new(:config_commands, 'console')
    method = aaa_a_service.default_method
    groups = aaa_a_service.default_groups
    aaa_a_service.groups_method_set(groups, method)

    p = get_pattern(:config_commands, 'console', groups, method)
    assert_show_match(command: show_cmd, pattern: p)
  end

  def test_commands_invalid_groups_method_set_groups
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
