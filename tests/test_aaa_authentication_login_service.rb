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

require File.expand_path("../ciscotest", __FILE__)
require File.expand_path(
  "../../lib/cisco_node_utils/aaa_authentication_login_service", __FILE__)

AAA_AUTH_LOGIN_SERVICE_METHOD_NONE = :none
AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL = :local
AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED = :unselected

class TestAaaAuthenticationLoginService < CiscoTestCase
  def unconfig_tacacs
    # unconfig
    s = @device.cmd("configure terminal")
    s = @device.cmd("no feature tacacs+")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
  end

  def unconfig_aaa
    # configure defaults = unconfigure
    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login default local")
    s = @device.cmd("aaa authentication login console local")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
  end

  def config_tacacs_servers(servers)
    s = @device.cmd("configure terminal")
    s = @device.cmd("feature tacacs+")
    servers.each do | server |
      s = @device.cmd("aaa group server tacacs+ #{server}")
    end
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
  end

  def aaaauthloginservices_default
    # change it to default
    s = @device.cmd("show run aaa all | no-more")
    prefix = "aaa authentication login"

    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login default local")
    s = @device.cmd("aaa authentication login console local")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
  end

  def aaaauthloginservice_detach(authloginservice, revert = true)
    aaaauthloginservices_default if revert != false
    begin
      authloginservice.destroy
    rescue Exception => e
      raise e.message + "\n(see CSCuu86609)"
    end
  end

  def get_match_line(name)
    s = @device.cmd("show run aaa all | no-more")
    prefix = "aaa authentication login"
    line = /#{prefix} #{name}/.match(s)
    line
  end

  def test_aaaauthloginservice_create_empty_service
    assert_raises(ArgumentError) do
      aaaauthloginservice = AaaAuthenticationLoginService.new("")
    end
  end

  def test_aaaauthloginservice_create_invalid_service
    assert_raises(TypeError) do
      aaaauthloginservice = AaaAuthenticationLoginService.new(:test)
    end
  end

  def test_aaaauthloginservice_create_service_default
    aaaauthloginservice = AaaAuthenticationLoginService.new("default")
    refute_nil(aaaauthloginservice,
               "Error: AAA authentication login service default create")
    aaaauthloginservice_detach(aaaauthloginservice) unless aaaauthloginservice.nil?
  end

  def test_aaaauthloginservice_create_service_console
    aaaauthloginservice = AaaAuthenticationLoginService.new("console")
    refute_nil(aaaauthloginservice,
                 "Error: AAA authentication login service console create")
    aaaauthloginservice_detach(aaaauthloginservice) unless aaaauthloginservice.nil?
  end

  def test_aaaauthloginservice_collection_with_service_default
    unconfig_aaa
    aaaauthloginservice_list = AaaAuthenticationLoginService.services
    refute_empty(aaaauthloginservice_list,
                 "Error: AAA Authentication Login service collection is not filled")
    assert_equal(1, aaaauthloginservice_list.size,
                 "Error:  AAA Authentication Login collection not reporting correct " +
                 " size (see CSCuu29429)")
    assert(aaaauthloginservice_list.key?("default"),
           "Error:  AAA Authentication Login collection does contain default")
    aaaauthloginservice_list.each do |name, aaaauthloginservice|
      assert_equal(name, aaaauthloginservice.name,
                   "Error: Invalid AaaAuthenticationLoginService #{name} in collection")
      assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL, aaaauthloginservice.method,
                   "Error: Invalid AaaAuthenticationLoginService method for defaultin collection")
      assert_empty(aaaauthloginservice.groups,
                   "Error: Invalid AaaAuthenticationLoginService groups for default in collection")
      aaaauthloginservice_detach(aaaauthloginservice, false)
    end
    aaaauthloginservices_default
  end

  def test_aaaauthloginservice_collection_with_service_default_and_console
    unconfig_aaa
    # preconfig console
    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login console none")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush

    aaaauthloginservice_list = AaaAuthenticationLoginService.services
    refute_empty(aaaauthloginservice_list,
                 "Error: AAA Authentication Login service collection is not filled")
    assert_equal(2, aaaauthloginservice_list.size,
                 "Error:  AAA Authentication Login collection not reporting correct size")
    assert(aaaauthloginservice_list.key?("default"),
                 "Error:  AAA Authentication Login collection does contain default")
     assert(aaaauthloginservice_list.key?("console"),
                 "Error:  AAA Authentication Login collection does contain console")
    aaaauthloginservice_list.each do |name, aaaauthloginservice|
      assert_equal(name, aaaauthloginservice.name,
                   "Error: Invalid AaaAuthenticationLoginService #{name} in collection")
      if name == "default"
        assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                     aaaauthloginservice.method,
                     "Error: Invalid AaaAuthLoginService method for default in " +
                     "collection (see CSCuu29429)")
      end

      if name == "console"
        assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE, aaaauthloginservice.method,
                     "Error: Invalid AaaAuthLoginService method for console in collection")
      end

      assert_equal([], aaaauthloginservice.groups,
                   "Error: Invalid AaaAuthLoginService groups for default in collection")
      aaaauthloginservice_detach(aaaauthloginservice, false)
    end
    aaaauthloginservices_default
  end

  def test_aaaauthloginservice_collection_with_service_default_and_console_with_group
    # preconfig servers
    servers = %w(group1 group2)
    config_tacacs_servers(servers)

    # preconfig console
    s = @device.cmd("configure terminal")
    # we need in some specific order
    s = @device.cmd("aaa authentication login default group group2 group1 none")
    s = @device.cmd("aaa authentication login console group group1")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush

    aaaauthloginservice_list = AaaAuthenticationLoginService.services
    refute_empty(aaaauthloginservice_list,
                 "Error: AAA Authentication Login service collection is not filled")
    assert_equal(2, aaaauthloginservice_list.size,
                 "Error:  AAA Authentication Login collection not reporting correct size")
    assert(aaaauthloginservice_list.key?("default"),
                 "Error:  AAA Authentication Login collection does contain default")
     assert(aaaauthloginservice_list.key?("console"),
                 "Error:  AAA Authentication Login collection does contain console")
    aaaauthloginservice_list.each do |name, aaaauthloginservice|
      assert_equal(name, aaaauthloginservice.name,
                   "Error: Invalid AaaAuthenticationLoginService #{name} in collection")

      if name == "default"
        assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE, aaaauthloginservice.method,
                     "Error: Invalid method for default in collection")
        groups = %w(group2 group1)
        assert_equal(groups, aaaauthloginservice.groups,
                     "Error: Invalid groups for default in collection")
      end

      if name == "console"
        assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED, aaaauthloginservice.method,
                     "Error: Invalid AaaAuthenticationLoginService method for console " +
                     "in collection (see CSCuu29429)")
        groups = ["group1"]
        assert_equal(groups, aaaauthloginservice.groups,
                     "Error: Invalid AaaAuthenticationLoginService groups for default in collection")
      end
      aaaauthloginservice_detach(aaaauthloginservice, false)
    end
    aaaauthloginservices_default
    unconfig_tacacs
  end

  def test_aaaauthloginservice_service_default_get_method
    aaaauthloginservice =
      AaaAuthenticationLoginService.new("default")

    # default case
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL, aaaauthloginservice.method,
                 "Error: AAA authentication login service default get method for local")

    # preconfig default
    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login default none")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE, aaaauthloginservice.method,
                 "Error: AAA authentication login service default get method for none")

    # preconfig servers
    servers = %w(bxb100 bxb200)
    config_tacacs_servers(servers)

    # preconfig default
    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login default group bxb100 bxb200")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED, aaaauthloginservice.method,
                 "Error: AAA authentication login service default get method for group unselected")

    # preconfig default
    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login default group bxb200 none")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE, aaaauthloginservice.method,
                 "Error: AAA authentication login service default get method for group and none")

    # cleanup
    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  def test_aaaauthloginservice_service_console_get_method
    aaaauthloginservice = AaaAuthenticationLoginService.new("console")

    # default case
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL, aaaauthloginservice.method,
                 "Error: AAA authentication login service console get method for local")

    # preconfig console
    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login console none")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE, aaaauthloginservice.method,
                 "Error: AAA authentication login service console get method for none")

    # preconfig servers
    servers = %w(bxb100 bxb200)
    config_tacacs_servers(servers)

    # preconfig console
    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login console group bxb100 bxb200")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED, aaaauthloginservice.method,
                 "Error: AAA authentication login service console get method for " +
                 "group unselected (see CSCuu29429)")

    # preconfig console
    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login console group bxb200 none")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE, aaaauthloginservice.method,
                 "Error: AAA authentication login service console get method for group and none")

    # cleanup
    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  def test_aaaauthloginservice_get_default_method
    # service default
    aaaauthloginservice =
      AaaAuthenticationLoginService.new("default")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice.default_method,
                 "Error: AAA authentication login service default,  default method")
    aaaauthloginservice_detach(aaaauthloginservice)

    # service console
    aaaauthloginservice =
      AaaAuthenticationLoginService.new("console")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice.default_method,
                 "Error: AAA authentication login service console,  default method")
    aaaauthloginservice_detach(aaaauthloginservice, false)
  end

  def test_aaaauthloginservice_service_default_get_groups
    aaaauthloginservice =
      AaaAuthenticationLoginService.new("default")

    # default case
    assert_equal(aaaauthloginservice.default_groups, aaaauthloginservice.groups,
                 "Error: AAA authentication login service default get groups for default")

    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # preconfig default
    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login default group bxb100 sjc200")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    groups = %w(bxb100 sjc200)
    assert_equal(groups, aaaauthloginservice.groups,
                 "Error: AAA authentication login service default get groups")

    # preconfig default
    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login default group sjc200 bxb100 rtp10 none")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    groups = %w(sjc200 bxb100 rtp10)
    assert_equal(groups, aaaauthloginservice.groups,
                 "Error: AAA authentication login service default get groups")

    # cleanup
    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  def test_aaaauthloginservice_service_console_get_groups
    aaaauthloginservice =
      AaaAuthenticationLoginService.new("console")

    # default case
    assert_equal(aaaauthloginservice.default_groups, aaaauthloginservice.groups,
                 "Error: AAA authentication login service console get groups for default")

    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # preconfig console
    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login console group bxb100 sjc200")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    groups = %w(bxb100 sjc200)
    assert_equal(groups, aaaauthloginservice.groups,
                 "Error: AAA authentication login service console get groups #{groups}" +
                 " (see CSCuu29429)")

    # preconfig console
    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login console group rtp10 bxb100 none")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    groups = %w(rtp10 bxb100)
    assert_equal(groups, aaaauthloginservice.groups,
                 "Error: AAA authentication login service console get groups #{groups}")

    # preconfig console
    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login console group sjc200 bxb100 rtp10")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    groups = %w(sjc200 bxb100 rtp10)
    assert_equal(groups, aaaauthloginservice.groups,
                 "Error: AAA authentication login service console get groups #{groups}")

    # cleanup
    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  def test_aaaauthloginservice_service_default_and_console_mix
    aaaauthloginservice_default =
      AaaAuthenticationLoginService.new("default")
    aaaauthloginservice_console =
      AaaAuthenticationLoginService.new("console")

    # default cases
    assert_equal(aaaauthloginservice_default.default_groups,
                 aaaauthloginservice_default.groups,
                 "Error: AAA authentication login default, get groups default")
    assert_equal(aaaauthloginservice_console.default_groups,
                 aaaauthloginservice_console.groups,
                 "Error: AAA authentication login console, get groups default")
     assert_equal(aaaauthloginservice_default.default_method,
                  aaaauthloginservice_default.method,
                 "Error: AAA authentication login default, get method default")
    assert_equal(aaaauthloginservice_console.default_method,
                 aaaauthloginservice_console.method,
                 "Error: AAA authentication login console, get method default")

    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    groups = %w(bxb100 sjc200)
    aaaauthloginservice_default.groups_method_set(
      groups, AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED)

    assert_equal(groups, aaaauthloginservice_default.groups,
                 "Error: AAA authentication login default, get groups #{groups}")
    assert_empty(aaaauthloginservice_console.groups,
                 "Error: AAA authentication login console, get groups non empty")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED,
                 aaaauthloginservice_default.method,
                 "Error: AAA authentication login default, get method")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_console.method,
                 "Error: AAA authentication login console, get method")

    # set groups
    aaaauthloginservice_default.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    aaaauthloginservice_console.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)

    # get
    assert(aaaauthloginservice_default.groups.empty?,
           "Error: AAA authentication login default ,get groups non empty")
    assert_empty(aaaauthloginservice_console.groups,
                 "Error: AAA authentication login console, get groups empty")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_default.method,
                 "Error: AAA authentication login default, get method none")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_console.method,
                 "Error: AAA authentication login console, get method none")

    # set groups
    aaaauthloginservice_default.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)
    aaaauthloginservice_console.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)

    # get
    assert_empty(aaaauthloginservice_default.groups,
                 "Error: AAA authentication login default, get groups non-empty")
    assert_empty(aaaauthloginservice_console.groups,
                 "Error: AAA authentication login console, get groups non-empty")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_default.method,
                 "Error: AAA authentication login default, get method local")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_console.method,
                 "Error: AAA authentication login console, get method local")

    # set groups
    aaaauthloginservice_default.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    aaaauthloginservice_console.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)

    # get
    assert_empty(aaaauthloginservice_default.groups,
                 "Error: AAA authentication login default, get groups non-empty")
    assert_empty(aaaauthloginservice_console.groups,
                 "Error: AAA authentication login console, get groups non-empty")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_default.method,
                 "Error: AAA authentication login default, get method none")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_console.method,
                 "Error: AAA authentication login console, get method local")

    # set groups
    aaaauthloginservice_default.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)
    aaaauthloginservice_console.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)

    # get
    assert_empty(aaaauthloginservice_default.groups,
                 "Error: AAA authentication login default, get groups non-empty")
    assert_empty(aaaauthloginservice_console.groups,
                 "Error: AAA authentication login console, get groups non-empty")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_default.method,
                 "Error: AAA authentication login default, get method local")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_console.method,
                 "Error: AAA authentication login console, get method none")

    # set groups
    groups_default = ["bxb100"]
    groups_console = %w(bxb100 sjc200)
    # CSCuu29429
    begin
    aaaauthloginservice_default.groups_method_set(
      groups_default, AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED)
    aaaauthloginservice_console.groups_method_set(
      groups_console, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    rescue Exception => e
      raise e.message + " (see CSCuu29429)"
    end

    # get
    assert_equal(groups_default,
                 aaaauthloginservice_default.groups,
                 "Error: AAA authentication login default, get groups #{groups}")
    assert_equal(groups_console,
                 aaaauthloginservice_console.groups,
                 "Error: AAA authentication login console, get groups #{groups}")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED,
                 aaaauthloginservice_default.method,
                 "Error: AAA authentication login default, get method local")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_console.method,
                 "Error: AAA authentication login console, get method none")

    # set same groups and method
    groups = ["bxb100"]
    aaaauthloginservice_default.groups_method_set(
      groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    aaaauthloginservice_console.groups_method_set(
      groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    # get
    assert_equal(groups,
                 aaaauthloginservice_default.groups,
                 "Error: AAA authentication login default, get groups #{groups}")
    assert_equal(groups,
                 aaaauthloginservice_console.groups,
                 "Error: AAA authentication login console, get groups #{groups}")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_default.method,
                 "Error: AAA authentication login default, get method none")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_console.method,
                 "Error: AAA authentication login console, get method none")

    # set group for console and empty for default
    groups = %w(bxb100 rtp10)
    aaaauthloginservice_default.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)
    aaaauthloginservice_console.groups_method_set(
      groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)

    # get
    assert_empty(aaaauthloginservice_default.groups,
                "Error: AAA authentication login default, get groups non empty")
    assert_equal(groups,
                 aaaauthloginservice_console.groups,
                 "Error: AAA authentication login console, get groups #{groups}")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_default.method,
                 "Error: AAA authentication login default, get method local")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_console.method,
                 "Error: AAA authentication login console, get method none")

    # set groups for default and empty for console
    groups = %w(bxb100 rtp10)
    aaaauthloginservice_default.groups_method_set(
      groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    aaaauthloginservice_console.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)

    # get
    assert_equal(groups,
                 aaaauthloginservice_default.groups,
                 "Error: AAA authentication login default, get groups #{groups}")
    assert_empty(aaaauthloginservice_console.groups,
                 "Error: AAA authentication login console, get groups non-empty")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_default.method,
                 "Error: AAA authentication login default, get method none")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL,
                 aaaauthloginservice_console.method,
                 "Error: AAA authentication login console, get method local")

    # set group for default and empty for console, same methos none
    groups = %w(bxb100 rtp10)
    aaaauthloginservice_default.groups_method_set(
      groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    aaaauthloginservice_console.groups_method_set(
      [], AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)

    # get
    assert_equal(groups,
                 aaaauthloginservice_default.groups,
                 "Error: AAA authentication login default, get groups #{groups}")
    assert_empty(aaaauthloginservice_console.groups,
                 "Error: AAA authentication login console, get groups non-empty")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_default.method,
                 "Error: AAA authentication login default, get method none")
    assert_equal(AAA_AUTH_LOGIN_SERVICE_METHOD_NONE,
                 aaaauthloginservice_console.method,
                 "Error: AAA authentication login console, get method none")

    # cleanup
    aaaauthloginservice_detach(aaaauthloginservice_default)
    aaaauthloginservice_detach(aaaauthloginservice_console)
    unconfig_tacacs
  end

  def test_aaaauthloginservice_get_default_groups
    # service default
    aaaauthloginservice =
      AaaAuthenticationLoginService.new("default")
    assert_empty(aaaauthloginservice.default_groups,
                 "Error: AAA authentication login default, default groups")
    aaaauthloginservice_detach(aaaauthloginservice)

    # service console
    aaaauthloginservice =
      AaaAuthenticationLoginService.new("console")
    assert_empty(aaaauthloginservice.default_groups,
                 "Error: AAA authentication login console, default groups")
    aaaauthloginservice_detach(aaaauthloginservice)
  end

  def test_aaaauthloginservice_service_default_set_groups
    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # service default
    service = "default"
    aaaauthloginservice =
      AaaAuthenticationLoginService.new(service)

    # one group and method is unselected
    method = AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED
    groups = ["bxb100"]
    aaaauthloginservice.groups_method_set(groups, method)
    match = "#{service} group bxb100"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AAA authentication login #{service}, set groups #{groups} #{method}")

    # multiple group and method is unselected
    method = AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED
    groups = %w(bxb100 sjc200)
    aaaauthloginservice.groups_method_set(groups, method)
    match = "#{service} group bxb100 sjc200"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AAA authentication login #{service}, set groups #{groups} #{method}")

    # multi group and method is none
    method = AAA_AUTH_LOGIN_SERVICE_METHOD_NONE
    groups = %w(rtp10 bxb100 sjc200)
    aaaauthloginservice.groups_method_set(groups, method)
    match = "#{service} group rtp10 bxb100 sjc200 none"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AAA authentication login #{service}, set groups #{groups} #{method}")

    # default group and method
    method = aaaauthloginservice.default_method
    groups = aaaauthloginservice.default_groups
    aaaauthloginservice.groups_method_set(groups, method)
    match = "#{service} local"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AAA authentication login #{service}, set default groups and method")

    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  def test_aaaauthloginservice_service_console_set_groups
    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # service console
    service = "console"
    aaaauthloginservice =
      AaaAuthenticationLoginService.new(service)

    # one group and method is unselected
    method = AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED
    groups = ["bxb100"]
    # CSCuu29429
    begin
    aaaauthloginservice.groups_method_set(groups, method)
    rescue Exception => e
      raise e.message + " (see CSCuu29429)"
    end
    match = "#{service} group bxb100"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AAA authentication login #{service}, set groups #{groups} #{method}")

    # multi group and method is unselected
    method = AAA_AUTH_LOGIN_SERVICE_METHOD_UNSELECTED
    groups = %w(bxb100 sjc200)
    aaaauthloginservice.groups_method_set(groups, method)
    match = "#{service} group bxb100 sjc200"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AAA authentication login #{service}, set groups #{groups} #{method}")

    # multi group and method is none
    method = AAA_AUTH_LOGIN_SERVICE_METHOD_NONE
    groups = %w(rtp10 bxb100 sjc200)
    aaaauthloginservice.groups_method_set(groups, method)
    match = "#{service} group rtp10 bxb100 sjc200 none"
    line = get_match_line(match)
    refute_nil(line,
               "Error: AAA authentication login #{service}, set groups #{groups} #{method}")

    # default group and method
    method = aaaauthloginservice.default_method
    groups = aaaauthloginservice.default_groups
    aaaauthloginservice.groups_method_set(groups, method)
    match = "#{service} local"
    line = get_match_line(match)
    assert_nil(line,
               "Error: AAA authentication login #{service}, set default groups and method")

    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  def test_aaaauthloginservice_service_set_groups_invalid_groups
    # preconfig servers
    servers = %w(bxb100 sjc200 rtp10)
    config_tacacs_servers(servers)

    # service default
    service = "default"
    aaaauthloginservice =
      AaaAuthenticationLoginService.new(service)

    # one invalid group
    groups = ["test1"]
    assert_raises(RuntimeError) do
      aaaauthloginservice.groups_method_set(
        groups, AAA_AUTH_LOGIN_SERVICE_METHOD_LOCAL)
    end

    # multiple groups with invalid group
    groups = %w(rtp10 test2 bxb100)
    assert_raises(RuntimeError, "(see CSCuu63677)") do
      aaaauthloginservice.groups_method_set(
        groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    end

    # multiple groups with invalid group
    groups = %w(test4 test2 bxb100)
    assert_raises(RuntimeError) do
      aaaauthloginservice.groups_method_set(
        groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    end

    # invalid array
    groups = ["bxb100", 100, "bxb100"]
    assert_raises(TypeError) do
      aaaauthloginservice.groups_method_set(
        groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    end
    aaaauthloginservice_detach(aaaauthloginservice)

    # repeat the test for service 'console'
    service = "console"
    aaaauthloginservice =
      AaaAuthenticationLoginService.new(service)

    # one invalid group
    groups = ["test1"]
    assert_raises(RuntimeError) do
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
    assert_raises(RuntimeError) do
      aaaauthloginservice.groups_method_set(
        groups, AAA_AUTH_LOGIN_SERVICE_METHOD_NONE)
    end
    aaaauthloginservice_detach(aaaauthloginservice)
    unconfig_tacacs
  end

  def test_aaaauthloginservice_service_set_groups_invalid_method
    # service default
    service = "default"
    aaaauthloginservice =
      AaaAuthenticationLoginService.new(service)

    assert_raises(TypeError) do
      aaaauthloginservice.groups_method_set([], "bxb100")
    end

    assert_raises(ArgumentError) do
      aaaauthloginservice.groups_method_set([], :invalid)
    end

    aaaauthloginservice_detach(aaaauthloginservice)

    # service console
    service = "console"
    aaaauthloginservice =
      AaaAuthenticationLoginService.new(service)

    assert_raises(TypeError) do
      aaaauthloginservice.groups_method_set([], "test")
    end

    assert_raises(TypeError) do
      aaaauthloginservice.groups_method_set([], 15)
    end

    aaaauthloginservice_detach(aaaauthloginservice)
  end
end
