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
require_relative '../lib/cisco_node_utils/aaa_authentication_login_service'

AAA_AUTH_LOGIN_SERVICE_METHOD_NONE = :none
AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL = :local
AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED = :unselected

# Test class for AAA Authentication Login Service
class TestAaaAuthenticationLoginService < CiscoTestCase
  def unconfig_tacacs
    config('no feature tacacs+')
  end

  def unconfig_aaa
    # configure defaults = unconfigure
    config('aaa authentication login default local')
    config('aaa authentication login console local')
  end

  def config_tacacs_servers(servers)
    config('feature tacacs+')
    servers.each do |server|
      config("aaa group server tacacs+ #{server}")
    end
  end

  def aaaauthloginservices_default
    config('aaa authentication login default local')
    config('aaa authentication login console local')
  end

  def aaaauthloginservice_detach(authloginservice, revert=true)
    aaaauthloginservices_default if revert != false
    authloginservice.destroy
  end

  def test_create_empty_service
    assert_raises(ArgumentError) do
      AaaAuthenticationLoginService.new('')
    end
  end

  def test_create_invalid_service
    assert_raises(TypeError) do
      AaaAuthenticationLoginService.new(:test)
    end
  end

  def test_create_service_default
    aaaauthloginservice = AaaAuthenticationLoginService.new('default')
    refute_nil(aaaauthloginservice,
               'Error: login service default create')
    aaaauthloginservice_detach(aaaauthloginservice) unless
      aaaauthloginservice.nil?
  end

  def test_create_service_console
    aaaauthloginservice = AaaAuthenticationLoginService.new('console')
    refute_nil(aaaauthloginservice,
               'Error: login service console create')
    aaaauthloginservice_detach(aaaauthloginservice) unless
      aaaauthloginservice.nil?
  end

  def test_collection_with_service_default
    unconfig_aaa
    aaaauthloginservice_list = AaaAuthenticationLoginService.services
    refute_empty(aaaauthloginservice_list,
                 'Error: service collection is not filled')
    assert_equal(1, aaaauthloginservice_list.size,
                 'Error:  collection not reporting correct ')
    assert(aaaauthloginservice_list.key?('default'),
           'Error:  collection does contain default')
    aaaauthloginservice_list.each do |name, aaaauthloginservice|
      assert_equal(name, aaaauthloginservice.name,
                   "Error: Invalid name #{name} in collection")
      assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                   aaaauthloginservice.method,
                   'Error: Invalid method for defaultin collection')
      assert_empty(aaaauthloginservice.groups,
                   'Error: Invalid groups for default in collection')
      aaaauthloginservice_detach(aaaauthloginservice, false)
    end
    aaaauthloginservices_default
  end

  def test_collection_with_service_default_and_console
    unconfig_aaa
    # preconfig console
    config('aaa authentication login console none')

    aaaauthloginservice_list = AaaAuthenticationLoginService.services
    refute_empty(aaaauthloginservice_list,
                 'Error: service collection is not filled')
    assert_equal(2, aaaauthloginservice_list.size,
                 'Error:  collection not reporting correct size')
    assert(aaaauthloginservice_list.key?('default'),
           'Error:  collection does contain default')
    assert(aaaauthloginservice_list.key?('console'),
           'Error:  collection does contain console')
    aaaauthloginservice_list.each do |name, aaaauthloginservice|
      assert_equal(name, aaaauthloginservice.name,
                   "Error: Invalid name #{name} in collection")
      if name == 'default'
        assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                     aaaauthloginservice.method,
                     'Error: Invalid method for default in collection')
      end

      if name == 'console'
        assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                     aaaauthloginservice.method,
                     'Error: Invalid method for console in collection')
      end

      assert_equal([], aaaauthloginservice.groups,
                   'Error: Invalid groups for default in collection')
      aaaauthloginservice_detach(aaaauthloginservice, false)
    end
    aaaauthloginservices_default
  end

  def test_collection_with_service_default_and_console_with_group
    # preconfig servers
    servers = %w(group1 group2)
    config_tacacs_servers(servers)

    # preconfig console
    # we need in some specific order
    config('aaa authentication login default group group2 group1 none',
           'aaa authentication login console group group1')

    aaaauthloginservice_list = AaaAuthenticationLoginService.services
    refute_empty(aaaauthloginservice_list,
                 'Error: service collection is not filled')
    assert_equal(2, aaaauthloginservice_list.size,
                 'Error: Login collection not reporting correct size')
    assert(aaaauthloginservice_list.key?('default'),
           'Error:  collection does contain default')
    assert(aaaauthloginservice_list.key?('console'),
           'Error:  collection does contain console')
    aaaauthloginservice_list.each do |name, aaaauthloginservice|
      assert_equal(name, aaaauthloginservice.name,
                   "Error: Invalid name #{name} in collection")

      if name == 'default'
        assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                     aaaauthloginservice.method,
                     'Error: Invalid method for default in collection')
        groups = %w(group2 group1)
        assert_equal(groups, aaaauthloginservice.groups,
                     'Error: Invalid groups for default in collection')
      end

      if name == 'console'
        assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED,
                     aaaauthloginservice.method,
                     'Error: Invalid method for console in collection')
        groups = ['group1']
        assert_equal(groups, aaaauthloginservice.groups,
                     'Error: Invalid groups for default in collection')
      end
      aaaauthloginservice_detach(aaaauthloginservice, false)
    end
    aaaauthloginservices_default
    unconfig_tacacs
  end

  def test_service_default_get_method
    aaaauthloginservice =
      AaaAuthenticationLoginService.new('default')

    # default case
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice.method,
                 'Error: login service default get method for local')

    # preconfig default
    config('aaa authentication login default none')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice.method,
                 'Error: login service default get method for none')

    # preconfig servers
    servers = %w(bxb100 bxb200)
    config_tacacs_servers(servers)

    # preconfig default
    config('aaa authentication login default group bxb100 bxb200')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED,
                 aaaauthloginservice.method,
                 'Error: login service group or method incorrect')

    # preconfig default
    config('aaa authentication login default group bxb200 none')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice.method,
                 "Error: login service group incorrect or method not 'none'")

    # cleanup
    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  def test_service_console_get_method
    aaaauthloginservice = AaaAuthenticationLoginService.new('console')

    # default case
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice.method,
                 "Error: login service method not 'local'")

    # preconfig console
    config('aaa authentication login console none')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice.method,
                 "Error: login service method not 'none'")

    # preconfig servers
    servers = %w(bxb100 bxb200)
    config_tacacs_servers(servers)

    # preconfig console
    config('aaa authentication login console group bxb100 bxb200')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED,
                 aaaauthloginservice.method,
                 "Error: login service method not 'unselected'")

    # preconfig console
    config('aaa authentication login console group bxb200 none')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice.method,
                 "Error: login service group incorrect or method not 'none'")

    # cleanup
    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  def test_get_default_method
    # service default
    aaaauthloginservice =
      AaaAuthenticationLoginService.new('default')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice.default_method,
                 'Error: login service default,  default method')
    aaaauthloginservice_detach(aaaauthloginservice)

    # service console
    aaaauthloginservice =
      AaaAuthenticationLoginService.new('console')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice.default_method,
                 'Error: login service console,  default method')
    aaaauthloginservice_detach(aaaauthloginservice, false)
  end

  def test_service_default_get_groups
    aaaauthloginservice =
      AaaAuthenticationLoginService.new('default')

    # default case
    assert_equal(aaaauthloginservice.default_groups, aaaauthloginservice.groups,
                 'Error: login service default get groups for default')

    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # preconfig default
    config('aaa authentication login default group bxb100 sjc200')
    groups = %w(bxb100 sjc200)
    assert_equal(groups, aaaauthloginservice.groups,
                 'Error: login service default get groups')

    # preconfig default
    config('aaa authentication login default group sjc200 bxb100 rtp10 none')
    groups = %w(sjc200 bxb100 rtp10)
    assert_equal(groups, aaaauthloginservice.groups,
                 'Error: login service default get groups')

    # cleanup
    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  def test_service_console_get_groups
    aaaauthloginservice =
      AaaAuthenticationLoginService.new('console')

    # default case
    assert_equal(aaaauthloginservice.default_groups, aaaauthloginservice.groups,
                 'Error: login service console get groups for default')

    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # preconfig console
    config('aaa authentication login console group bxb100 sjc200')
    groups = %w(bxb100 sjc200)
    assert_equal(groups, aaaauthloginservice.groups,
                 "Error: login service console get groups #{groups}")

    # preconfig console
    config('aaa authentication login console group rtp10 bxb100 none')
    groups = %w(rtp10 bxb100)
    assert_equal(groups, aaaauthloginservice.groups,
                 "Error: login service console get groups #{groups}")

    # preconfig console
    config('aaa authentication login console group sjc200 bxb100 rtp10')
    groups = %w(sjc200 bxb100 rtp10)
    assert_equal(groups, aaaauthloginservice.groups,
                 "Error: login service console get groups #{groups}")

    # cleanup
    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  # rubocop:disable Metrics/MethodLength
  # TODO: Consider refactoring this method
  def test_service_default_and_console_mix
    aaaauthloginservice_default =
      AaaAuthenticationLoginService.new('default')
    aaaauthloginservice_console =
      AaaAuthenticationLoginService.new('console')

    # default cases
    assert_equal(aaaauthloginservice_default.default_groups,
                 aaaauthloginservice_default.groups,
                 'Error: login default, get groups default')
    assert_equal(aaaauthloginservice_console.default_groups,
                 aaaauthloginservice_console.groups,
                 'Error: login console, get groups default')
    assert_equal(aaaauthloginservice_default.default_method,
                 aaaauthloginservice_default.method,
                 'Error: login default, get method default')
    assert_equal(aaaauthloginservice_console.default_method,
                 aaaauthloginservice_console.method,
                 'Error: login console, get method default')

    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    groups = %w(bxb100 sjc200)
    aaaauthloginservice_default.groups_method_set(
      groups, AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED)

    assert_equal(groups, aaaauthloginservice_default.groups,
                 "Error: login default, get groups #{groups}")
    assert_empty(aaaauthloginservice_console.groups,
                 'Error: login console, get groups non empty')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED,
                 aaaauthloginservice_default.method,
                 'Error: login default, get method')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_console.method,
                 'Error: login console, get method')

    # set groups
    aaaauthloginservice_default.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    aaaauthloginservice_console.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)

    # get
    assert(aaaauthloginservice_default.groups.empty?,
           'Error: login default ,get groups non empty')
    assert_empty(aaaauthloginservice_console.groups,
                 'Error: login console, get groups empty')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_default.method,
                 'Error: login default, get method none')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_console.method,
                 'Error: login console, get method none')

    # set groups
    aaaauthloginservice_default.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)
    aaaauthloginservice_console.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)

    # get
    assert_empty(aaaauthloginservice_default.groups,
                 'Error: login default, get groups non-empty')
    assert_empty(aaaauthloginservice_console.groups,
                 'Error: login console, get groups non-empty')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_default.method,
                 'Error: login default, get method local')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_console.method,
                 'Error: login console, get method local')

    # set groups
    aaaauthloginservice_default.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    aaaauthloginservice_console.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)

    # get
    assert_empty(aaaauthloginservice_default.groups,
                 'Error: login default, get groups non-empty')
    assert_empty(aaaauthloginservice_console.groups,
                 'Error: login console, get groups non-empty')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_default.method,
                 'Error: login default, get method none')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_console.method,
                 'Error: login console, get method local')

    # set groups
    aaaauthloginservice_default.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)
    aaaauthloginservice_console.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)

    # get
    assert_empty(aaaauthloginservice_default.groups,
                 'Error: login default, get groups non-empty')
    assert_empty(aaaauthloginservice_console.groups,
                 'Error: login console, get groups non-empty')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_default.method,
                 'Error: login default, get method local')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_console.method,
                 'Error: login console, get method none')

    # set groups
    groups_default = ['bxb100']
    groups_console = %w(bxb100 sjc200)
    aaaauthloginservice_default.groups_method_set(
      groups_default, AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED)
    aaaauthloginservice_console.groups_method_set(
      groups_console, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)

    # get
    assert_equal(groups_default,
                 aaaauthloginservice_default.groups,
                 "Error: login default, get groups #{groups}")
    assert_equal(groups_console,
                 aaaauthloginservice_console.groups,
                 "Error: login console, get groups #{groups}")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED,
                 aaaauthloginservice_default.method,
                 'Error: login default, get method local')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_console.method,
                 'Error: login console, get method none')

    # set same groups and method
    groups = ['bxb100']
    aaaauthloginservice_default.groups_method_set(
      groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    aaaauthloginservice_console.groups_method_set(
      groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    # get
    assert_equal(groups,
                 aaaauthloginservice_default.groups,
                 "Error: login default, get groups #{groups}")
    assert_equal(groups,
                 aaaauthloginservice_console.groups,
                 "Error: login console, get groups #{groups}")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_default.method,
                 'Error: login default, get method none')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_console.method,
                 'Error: login console, get method none')

    # set group for console and empty for default
    groups = %w(bxb100 rtp10)
    aaaauthloginservice_default.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)
    aaaauthloginservice_console.groups_method_set(
      groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)

    # get
    assert_empty(aaaauthloginservice_default.groups,
                 'Error: login default, get groups non empty')
    assert_equal(groups,
                 aaaauthloginservice_console.groups,
                 "Error: login console, get groups #{groups}")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_default.method,
                 'Error: login default, get method local')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_console.method,
                 'Error: login console, get method none')

    # set groups for default and empty for console
    groups = %w(bxb100 rtp10)
    aaaauthloginservice_default.groups_method_set(
      groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    aaaauthloginservice_console.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)

    # get
    assert_equal(groups,
                 aaaauthloginservice_default.groups,
                 "Error: login default, get groups #{groups}")
    assert_empty(aaaauthloginservice_console.groups,
                 'Error: login console, get groups non-empty')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_default.method,
                 'Error: login default, get method none')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_console.method,
                 'Error: login console, get method local')

    # set group for default and empty for console, same methos none
    groups = %w(bxb100 rtp10)
    aaaauthloginservice_default.groups_method_set(
      groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    aaaauthloginservice_console.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)

    # get
    assert_equal(groups,
                 aaaauthloginservice_default.groups,
                 "Error: login default, get groups #{groups}")
    assert_empty(aaaauthloginservice_console.groups,
                 'Error: login console, get groups non-empty')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_default.method,
                 'Error: login default, get method none')
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_console.method,
                 'Error: login console, get method none')

    # cleanup
    aaaauthloginservice_detach(aaaauthloginservice_default)
    aaaauthloginservice_detach(aaaauthloginservice_console)
    unconfig_tacacs
  end
  # rubocop:enable Metrics/MethodLength,Metrics/AbcSize

  def test_get_default_groups
    # service default
    aaaauthloginservice =
      AaaAuthenticationLoginService.new('default')
    assert_empty(aaaauthloginservice.default_groups,
                 'Error: login default, default groups')
    aaaauthloginservice_detach(aaaauthloginservice)

    # service console
    aaaauthloginservice =
      AaaAuthenticationLoginService.new('console')
    assert_empty(aaaauthloginservice.default_groups,
                 'Error: login console, default groups')
    aaaauthloginservice_detach(aaaauthloginservice)
  end

  def test_service_default_set_groups
    # preconfig servers
    prefix = '^aaa authentication login default group '
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # service default
    service = 'default'
    aaaauthloginservice =
      AaaAuthenticationLoginService.new(service)

    # one group and method is unselected
    method = AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED
    groups = ['bxb100']
    aaaauthloginservice.groups_method_set(groups, method)
    assert_show_match(command: 'show run aaa all | no-more',
                      pattern: Regexp.new(prefix + groups.join(' ')))

    # multiple group and method is unselected
    method = AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED
    groups = %w(bxb100 sjc200)
    aaaauthloginservice.groups_method_set(groups, method)
    assert_show_match(command: 'show run aaa all | no-more',
                      pattern: Regexp.new(prefix + groups.join(' ')))

    # multi group and method is none
    method = AAA_AUTH_LOGIN_SERVICE_METHOD_NONE
    groups = %w(rtp10 bxb100 sjc200)
    aaaauthloginservice.groups_method_set(groups, method)
    assert_show_match(command: 'show run aaa all | no-more',
                      pattern: Regexp.new(prefix + groups.join(' ')))

    # default group and method
    method = aaaauthloginservice.default_method
    groups = aaaauthloginservice.default_groups
    aaaauthloginservice.groups_method_set(groups, method)
    assert_show_match(command: 'show run aaa all | no-more',
                      pattern: /^aaa authentication login default local/)

    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  def test_service_console_set_groups
    # preconfig servers
    prefix = '^aaa authentication login console group '
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # service console
    service = 'console'
    aaaauthloginservice =
      AaaAuthenticationLoginService.new(service)

    # one group and method is unselected
    method = AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED
    groups = ['bxb100']
    aaaauthloginservice.groups_method_set(groups, method)
    assert_show_match(command: 'show run aaa all | no-more',
                      pattern: Regexp.new(prefix + groups.join(' ')))

    # multi group and method is unselected
    method = AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED
    groups = %w(bxb100 sjc200)
    aaaauthloginservice.groups_method_set(groups, method)
    assert_show_match(command: 'show run aaa all | no-more',
                      pattern: Regexp.new(prefix + groups.join(' ')))

    # multi group and method is none
    method = AAA_AUTH_LOGIN_SERVICE_METHOD_NONE
    groups = %w(rtp10 bxb100 sjc200)
    aaaauthloginservice.groups_method_set(groups, method)
    assert_show_match(command: 'show run aaa all | no-more',
                      pattern: Regexp.new(prefix + groups.join(' ')))

    # default group and method
    method = aaaauthloginservice.default_method
    groups = aaaauthloginservice.default_groups
    aaaauthloginservice.groups_method_set(groups, method)
    refute_show_match(command: 'show run aaa all | no-more',
                      pattern: /^aaa authentication login console local/)

    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  def test_service_set_groups_invalid_groups
    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # service default
    service = 'default'
    aaaauthloginservice =
      AaaAuthenticationLoginService.new(service)

    # one invalid group
    groups = ['test1']
    assert_raises(RuntimeError) do
      aaaauthloginservice.groups_method_set(
        groups, AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)
    end

    # multiple groups with invalid group
    groups = %w(rtp10 test2 bxb100)
    assert_raises(CliError) do
      aaaauthloginservice.groups_method_set(
        groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    end

    # multiple groups with invalid group
    groups = %w(test4 test2 bxb100)
    assert_raises(CliError) do
      aaaauthloginservice.groups_method_set(
        groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    end

    # invalid array
    groups = ['bxb100', 100, 'bxb100']
    assert_raises(TypeError) do
      aaaauthloginservice.groups_method_set(
        groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    end
    aaaauthloginservice_detach(aaaauthloginservice)

    # repeat the test for service 'console'
    service = 'console'
    aaaauthloginservice =
      AaaAuthenticationLoginService.new(service)

    # one invalid group
    groups = ['test1']
    assert_raises(CliError) do
      aaaauthloginservice.groups_method_set(
        groups, AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED)
    end

    # multiple group with invalid group
    groups = %w(rtp1 test1 bxb100)
    assert_raises(RuntimeError) do
      aaaauthloginservice.groups_method_set(
        groups, AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)
    end

    # multiple group with invalid group
    groups = %w(rtp10 test1 bxb100)
    assert_raises(CliError) do
      aaaauthloginservice.groups_method_set(
        groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    end
    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  def test_service_set_groups_invalid_method
    # service default
    service = 'default'
    aaaauthloginservice =
      AaaAuthenticationLoginService.new(service)

    assert_raises(TypeError) do
      aaaauthloginservice.groups_method_set([], 'bxb100')
    end

    assert_raises(ArgumentError) do
      aaaauthloginservice.groups_method_set([], :invalid)
    end

    aaaauthloginservice_detach(aaaauthloginservice)

    # service console
    service = 'console'
    aaaauthloginservice =
      AaaAuthenticationLoginService.new(service)

    assert_raises(TypeError) do
      aaaauthloginservice.groups_method_set([], 'test')
    end

    assert_raises(TypeError) do
      aaaauthloginservice.groups_method_set([], 15)
    end

    aaaauthloginservice_detach(aaaauthloginservice)
  end
end
