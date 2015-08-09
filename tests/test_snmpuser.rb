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

require File.expand_path("../ciscotest", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/snmpuser", __FILE__)

DEFAULT_SNMP_USER_AUTH_PASSWORD = ""
DEFAULT_SNMP_USER_PRIV_PASSWORD = ""
DEFAULT_SNMP_USER_GROUP_NAME = "network-operator"

class TestSnmpUser < CiscoTestCase
  ## test cases starts here

  def test_snmpuser_collection_not_empty
    s = @device.cmd("conf t")
    s = @device.cmd("snmp-server user tester")
    s = @device.cmd("end")
    # flush cache
    node.cache_flush
    snmpusers = SnmpUser.users()
    assert_equal(false, snmpusers.empty?(),
                 "SnmpUser collection is empty")
    s = @device.cmd("conf t")
    s = @device.cmd("no snmp-server user tester")
    s = @device.cmd("end")
    node.cache_flush
  end

  def test_engine_id_valid_and_none
    s = @device.cmd("conf t")
    s = @device.cmd("snmp-server user tester auth sha password engineID 22:22:22:22:23:22")
    s = @device.cmd("snmp-server user tester2")
    s = @device.cmd("end")

    node.cache_flush
    snmpusers = SnmpUser.users()

    snmpusers.each { |name, snmpuser|
      if snmpuser.name == "tester"
        assert_equal("22:22:22:22:23:22", snmpuser.engine_id)
        snmpuser.destroy
      elsif snmpuser.name == "tester2"
        assert_equal("", snmpuser.engine_id)
        snmpuser.destroy
      end
    }
  end

  def test_snmpuser_create_name_empty
    name = ""
    groups = []
    groups << "network-admin"
    assert_raises(ArgumentError) do
      snmpuser = SnmpUser.new(name,
                              groups,
                              :none, "",
                              :none, "",
                              false,
                              "")
    end
  end

  def test_snmpuser_create_with_single_invalid_group_noauth_nopriv
    name = "userv3test"
    groups = []
    groups << "network-admin123"
    assert_raises(CliError) do
      snmpuser = SnmpUser.new(name,
                              groups,
                              :none, "",
                              :none, "",
                              false,
                              "")
    end
  end

  def test_snmpuser_create_with_single_group_noauth_nopriv
    name = "userv3test2"
    groups = []
    groups << "network-admin"
    snmpuser = SnmpUser.new(name,
                            groups,
                            :none, "",
                            :none, "",
                            false,
                            "")
    s = @device.cmd("show run snmp all | no-more")
    line = /snmp-server user #{name} network-admin/.match(s)
    # puts "line: #{line}"
    refute(line.nil?)
    snmpuser.destroy
  end

  def test_snmpuser_create_with_multi_group_noauth_nopriv
    name = "userv3test3"
    groups = []
    groups << "network-admin"
    groups << "vdc-admin"
    snmpuser = SnmpUser.new(name,
                            groups,
                            :none, "",
                            :none, "",
                            false,
                            "")
    s = @device.cmd("show run snmp all | no-more")
    groups.each do | group |
      line = /snmp-server user #{name} #{group}/.match(s)
      # puts "line: #{line}"
      refute(line.nil?)
    end
    snmpuser.destroy
  end

  def test_snmpuser_destroy
    name = "userv3testdestroy"
    group = "network-operator"
    s = @device.cmd("configure terminal")
    s = @device.cmd("snmp-server user #{name} #{group}")
    s = @device.cmd("end")
    node.cache_flush

    node.cache_flush

    # get user
    snmpusers = SnmpUser.users()
    snmpusers.each do |key, snmpuser|
      # puts "name: #{snmpuser.name}"
      if key == name
        assert_equal(snmpuser.name, name)
        assert(snmpuser.engine_id.empty?)
        # destroy the user
        snmpuser.destroy
        break
      end
    end
    # check user got removed.
    s = @device.cmd("show run snmp all | no-more")
    line = /snmp-server user #{name} #{group}/.match(s)
    assert(line.nil?)
    assert(SnmpUser.users[name].nil?)
  end

  def test_snmpuser_auth_password_equal_invalid_param
    name = "testV3PwEqualInvalid"
    auth_pw = "test1234567"
    s = @device.cmd("configure terminal")
    s = @device.cmd("snmp-server user #{name} network-admin auth md5 #{auth_pw}")
    s = @device.cmd("end")

    # flush cache
    node.cache_flush
    # get users
    snmpusers = SnmpUser.users()
    s = @device.cmd("show snmp user | no-more")
    snmpusers.each do |key, snmpuser|
      refute(snmpuser.auth_password_equal?("", false)) if key == name
    end
    # unconfigure
    s = @device.cmd("configure terminal")
    s = @device.cmd("no snmp-server user #{name}")
    s = @device.cmd("end")
    node.cache_flush
  end

  def test_snmpuser_auth_priv_password_equal_invalid_param
    name = "testV3PwEqualInvalid"
    auth_pw = "test1234567"
    s = @device.cmd("configure terminal")
    s = @device.cmd("snmp-server user #{name} network-admin auth md5 #{auth_pw} priv #{auth_pw}")
    s = @device.cmd("end")

    # flush cache
    node.cache_flush
    # get users
    snmpusers = SnmpUser.users()
    snmpusers.each do |key, snmpuser|
      if key == name
        refute(snmpuser.auth_password_equal?("", false))
        refute(snmpuser.priv_password_equal?("", false))
      end
    end
    # unconfigure
    s = @device.cmd("configure terminal")
    s = @device.cmd("no snmp-server user #{name}")
    s = @device.cmd("end")
    node.cache_flush
  end

  def test_snmpuser_auth_password_equal_priv_invalid_param
    name = "testV3PwEqualInvalid"
    auth_pw = "test1234567"
    s = @device.cmd("configure terminal")
    s = @device.cmd("snmp-server user #{name} network-operator auth md5 #{auth_pw} priv #{auth_pw}")
    s = @device.cmd("end")

    # flush cache
    node.cache_flush
    # get users
    snmpusers = SnmpUser.users()
    snmpusers.each do |key, snmpuser|
      if key == name
        assert(snmpuser.auth_password_equal?(auth_pw, false))
        refute(snmpuser.priv_password_equal?("", false))
      end
    end
    # unconfigure
    s = @device.cmd("configure terminal")
    s = @device.cmd("no snmp-server user #{name}")
    s = @device.cmd("end")
    node.cache_flush
  end

  def test_snmpuser_auth_password_not_equal
    name = "testV3PwEqual"
    auth_pw = "test1234567"
    s = @device.cmd("configure terminal")
    s = @device.cmd("snmp-server user #{name} network-admin auth md5 #{auth_pw}")
    s = @device.cmd("end")

    # flush cache
    node.cache_flush
    # get users
    snmpusers = SnmpUser.users()
    snmpusers.each do |key, snmpuser|
      refute(snmpuser.auth_password_equal?("test12345", false)) if key == name
    end
    s = @device.cmd("configure terminal")
    s = @device.cmd("no snmp-server user #{name}")
    s = @device.cmd("end")
    node.cache_flush
  end

  def test_snmpuser_auth_password_equal
    name = "testV3PwEqual"
    auth_pw = "test1234567"
    s = @device.cmd("configure terminal")
    s = @device.cmd("snmp-server user #{name} network-admin auth md5 #{auth_pw}")
    s = @device.cmd("end")

    # flush cache
    node.cache_flush
    # get users
    snmpusers = SnmpUser.users()
    snmpusers.each do |key, snmpuser|
      assert(snmpuser.auth_password_equal?(auth_pw, false)) if key == name
    end
    s = @device.cmd("configure terminal")
    s = @device.cmd("no snmp-server user #{name}")
    s = @device.cmd("end")
    node.cache_flush
  end

  def test_snmpuser_auth_clear_password_localizedkey_false
    name = "testV3ClearPwLocalFalse"
    auth_pw = "test123456"
    groups = []
    groups << "network-admin"
    assert_raises(CliError) do
      snmpuser = SnmpUser.new(name,
                              groups,
                              :sha, auth_pw,
                              :none, "",
                              true,
                              "")
    end
  end

  def test_snmpuser_auth_password_equal_localizedkey
    name = "testV3PwEqual"
    auth_pw = "0xfe6cf9aea159c2c38e0a79ec23ed3cbb"
    s = @device.cmd("configure terminal")
    s = @device.cmd("snmp-server user #{name} network-admin auth md5 #{auth_pw} localizedkey")
    s = @device.cmd("end")

    # flush cache
    node.cache_flush
    # get users
    snmpusers = SnmpUser.users()
    snmpusers.each do |key, snmpuser|
      if key == name
        assert(snmpuser.auth_password_equal?(auth_pw, true))
        # we should verify that if we give a wrong password, the api will return false
        refute(snmpuser.auth_password_equal?("0xfe6c", true))
      end
    end
    s = @device.cmd("configure terminal")
    s = @device.cmd("no snmp-server user #{name}")
    s = @device.cmd("end")
    node.cache_flush
  end

  def test_snmpuser_auth_priv_password_equal_localizedkey
    name = "testV3PwEqual"
    auth_pw = "0xfe6cf9aea159c2c38e0a79ec23ed3cbb"
    priv_pw = "0x29916eac22d90362598abef1b9045018"
    s = @device.cmd("configure terminal")
    s = @device.cmd("snmp-server user #{name} network-admin auth md5 #{auth_pw} priv aes-128 #{priv_pw} localizedkey")
    s = @device.cmd("end")

    # flush cache
    node.cache_flush
    # get users
    snmpusers = SnmpUser.users()
    snmpusers.each do |key, snmpuser|
      if key == name
        assert(snmpuser.auth_password_equal?(auth_pw, true))
        assert(snmpuser.priv_password_equal?(priv_pw, true))
        refute(snmpuser.priv_password_equal?("0x2291", true))
      end
    end
    s = @device.cmd("configure terminal")
    s = @device.cmd("no snmp-server user #{name}")
    s = @device.cmd("end")
    node.cache_flush
  end

  def test_snmpuser_auth_priv_des_password_equal
    name = "testV3PwEqual"
    auth_pw = "test1234567"
    priv_pw = "testdes1234"
    s = @device.cmd("configure terminal")
    s = @device.cmd("snmp-server user #{name} network-operator auth md5 #{auth_pw} priv #{priv_pw}")
    s = @device.cmd("end")

    # flush cache
    node.cache_flush
    # get users
    snmpusers = SnmpUser.users()
    s = @device.cmd("show snmp user | no-more")
    snmpusers.each do |key, snmpuser|
      if key == name
        assert(snmpuser.auth_password_equal?(auth_pw, false))
        assert(snmpuser.priv_password_equal?(priv_pw, false))
      end
    end
    s = @device.cmd("configure terminal")
    s = @device.cmd("no snmp-server user #{name}")
    s = @device.cmd("end")
    node.cache_flush
  end

  def test_snmpuser_create_with_single_group_unknown_auth_nopriv
    name = "userv3testUnknownAuth"
    groups = []
    groups << "network-admin"
    assert_raises(ArgumentError) do
      snmpuser = SnmpUser.new(name,
                              groups,
                              :none, "test12345",
                              :none, "",
                              false,
                              "")
    end
  end

  def test_snmpuser_create_with_single_group_auth_unknown_priv
    name = "userv3testUnknownPriv"
    groups = []
    groups << "network-admin"
    assert_raises(ArgumentError) do
      snmpuser = SnmpUser.new(name,
                              groups,
                              :sha, "test12345",
                              :none, "test12345",
                              false,
                              "")
    end
  end

  def test_snmpuser_create_with_single_group_auth_md5_nopriv
   name = "userv3test5"
   groups = []
   groups << "network-admin"
   auth_pw = "test1234567"
   snmpuser = SnmpUser.new(name,
                           groups,
                           :md5, auth_pw,
                           :none, "",
                           false, # clear text
                           "")
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   line = /snmp-server user #{name} network-admin auth md5 \S+ localizedkey/.match(s)
   # puts "line: #{line}"
   refute(line.nil?)
   snmpuser.destroy
  end

  def test_snmpuser_create_with_single_group_auth_md5_nopriv_pw_localized
   name = "userv3testauth"
   groups = []
   groups << "network-admin"
   auth_pw = "0xfe6cf9aea159c2c38e0a79ec23ed3cbb"
   snmpuser = SnmpUser.new(name,
                           groups,
                           :md5, auth_pw,
                           :none, "",
                           true, # localized
                           "")
   assert_equal(snmpuser.name, name)
   assert(snmpuser.engine_id.empty?)
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   # puts "cmd #{s}"
   line = /snmp-server user #{name} network-admin auth md5 #{auth_pw} localizedkey/.match(s)
   # puts "line: #{line}"
   refute(line.nil?)
   snmpuser.destroy
  end

 def test_snmpuser_create_with_single_group_auth_sha_nopriv
   name = "userv3testsha"
   groups = []
   groups << "network-admin"
   auth_pw = "test1234567"
   snmpuser = SnmpUser.new(name,
                           groups,
                           :sha, auth_pw,
                           :none, "",
                           false, # clear text
                           "")
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   line = /snmp-server user #{name} network-admin auth sha \S+ localizedkey/.match(s)
   # puts "line: #{line}"
   refute(line.nil?)
   snmpuser.destroy
 end

 def test_snmpuser_create_with_single_group_auth_sha_clear_pw_nopriv_pw_localized_true
   name = "userv3testauthsha1"
   groups = []
   groups << "network-admin"
   auth_pw = "test123456"
   assert_raises(CliError) do
     snmpuser = SnmpUser.new(name,
                             groups,
                             :sha, auth_pw,
                             :none, "",
                             true, # localized key
                             "")
   end
 end

 def test_snmpuser_create_with_single_group_auth_sha_short_length_pw_nopriv
   name = "userv3testauthsha2"
   groups = []
   groups << "network-admin"
   auth_pw = "test"  # NXOS Password must be atleast 8 characters
   assert_raises(CliError) do
     snmpuser = SnmpUser.new(name,
                             groups,
                             :sha, auth_pw,
                             :none, "",
                             false, # localized key
                             "")
   end
 end

 # If the auth pw is in hex and localized key param in constructor is false,
 # then the pw got localized by the device again.
 def test_snmpuser_create_with_single_group_auth_sha_nopriv_pw_localized_localizedkey_false
   name = "userv3testauthsha3"
   groups = []
   groups << "network-admin"
   auth_pw = "0xfe6cf9aea159c2c38e0a79ec23ed3cbb"

   snmpuser = SnmpUser.new(name,
                           groups,
                           :sha, auth_pw,
                           :none, "",
                           false, # localized key
                           "")
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   # puts "cmd #{s}"
   line = /snmp-server user #{name} network-admin auth sha \S+ localizedkey/.match(s)
   # puts "line: #{line}"
   refute(line.nil?)
   snmpuser.destroy
 end

 def test_snmpuser_create_with_single_group_auth_sha_nopriv_pw_localized
   name = "userv3testauthsha4"
   groups = []
   groups << "network-admin"
   auth_pw = "0xfe6cf9aea159c2c38e0a79ec23ed3cbb"
   snmpuser = SnmpUser.new(name,
                           groups,
                           :sha, auth_pw,
                           :none, "",
                           true, # localized
                           "")
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   # puts "cmd #{s}"
   line = /snmp-server user #{name} network-admin auth sha #{auth_pw} localizedkey/.match(s)
   # puts "line: #{line}"
   refute(line.nil?)
   snmpuser.destroy
 end

 def test_snmpuser_create_with_single_group_auth_md5_priv_des
   name = "userv3test6"
   groups = []
   groups << "network-admin"
   auth_pw = "test1234567"
   priv_pw = "priv1234567des"
   snmpuser = SnmpUser.new(name,
                           groups,
                           :md5, auth_pw,
                           :des, priv_pw,
                           false, # clear text
                           "")
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   line = /snmp-server user #{name} network-admin auth md5 \S+ priv \S+ localizedkey/.match(s)
   # puts "line: #{line}"
   refute(line.nil?)
   snmpuser.destroy
 end

 def test_snmpuser_create_with_single_group_auth_md5_priv_des_pw_localized
   name = "userv3testauth"
   groups = []
   groups << "network-admin"
   auth_pw = "0xfe6cf9aea159c2c38e0a79ec23ed3cbb"
   priv_pw = "0xfe6cf9aea159c2c38e0a79ec23ed3cbb"
   snmpuser = SnmpUser.new(name,
                           groups,
                           :md5, auth_pw,
                           :des, priv_pw,
                           true, # localized
                           "")
    s = @device.cmd("show run snmp all | in #{name} | no-more")
   # puts "cmd #{s}"
   line = /snmp-server user #{name} network-admin auth md5 #{auth_pw} priv #{priv_pw} localizedkey/.match(s)
   # puts "line: #{line}"
   refute(line.nil?)
   snmpuser.destroy
 end

 def test_snmpuser_create_with_single_group_auth_md5_priv_aes128
   name = "userv3test7"
   groups = []
   groups << "network-admin"
   auth_pw = "test1234567"
   priv_pw = "priv1234567aes"
   snmpuser = SnmpUser.new(name,
                           groups,
                           :md5, auth_pw,
                           :aes128, priv_pw,
                           false, # clear text
                           "")
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   line = /snmp-server user #{name} network-admin auth md5 \S+ priv aes-128 \S+ localizedkey/.match(s)
   # puts "line: #{line}"
   refute(line.nil?)
   snmpuser.destroy
 end

 def test_snmpuser_create_with_single_group_auth_md5_priv_aes128_pw_localized
   name = "userv3testauth"
   groups = []
   groups << "network-admin"
   auth_pw = "0xfe6cf9aea159c2c38e0a79ec23ed3cbb"
   priv_pw = "0xfe6cf9aea159c2c38e0a79ec23ed3cbb"
   snmpuser = SnmpUser.new(name,
                           groups,
                           :md5, auth_pw,
                           :aes128, priv_pw,
                           true, # localized
                           "")
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   # puts "cmd #{s}"
   line = /snmp-server user #{name} network-admin auth md5 #{auth_pw} priv aes-128 #{priv_pw} localizedkey/.match(s)
   # puts "line: #{line}"
   refute(line.nil?)
   snmpuser.destroy
 end

 def test_snmpuser_create_with_single_group_auth_sha_priv_des
   name = "userv3test8"
   groups = []
   groups << "network-admin"
   auth_pw = "test1234567"
   priv_pw = "priv1234567des"
   snmpuser = SnmpUser.new(name,
                           groups,
                           :sha, auth_pw,
                           :des, priv_pw,
                           false, # clear text
                           "")
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   line = /snmp-server user #{name} network-admin auth sha \S+ priv \S+ localizedkey/.match(s)
   # puts "line: #{line}"
   refute(line.nil?)
   snmpuser.destroy
 end

 def test_snmpuser_create_with_single_group_auth_md5_priv_sha_pw_localized
   name = "userv3testauth"
   groups = []
   groups << "network-admin"
   auth_pw = "0xfe6cf9aea159c2c38e0a79ec23ed3cbb"
   priv_pw = "0xfe6cf9aea159c2c38e0a79ec23ed3cbb"
   snmpuser = SnmpUser.new(name,
                           groups,
                           :sha, auth_pw,
                           :des, priv_pw,
                           true, # localized
                           "")
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   # puts "cmd #{s}"
   line = /snmp-server user #{name} network-admin auth sha #{auth_pw} priv #{priv_pw} localizedkey/.match(s)
   # puts "line: #{line}"
   refute(line.nil?)
   snmpuser.destroy
 end

 def test_snmpuser_create_with_single_group_auth_sha_priv_aes128
   name = "userv3test9"
   groups = []
   groups << "network-admin"
   auth_pw = "test1234567"
   priv_pw = "priv1234567aes"
   snmpuser = SnmpUser.new(name,
                           groups,
                           :sha, auth_pw,
                           :aes128, priv_pw,
                           false, # clear text
                           "")
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   line = /snmp-server user #{name} network-admin auth sha \S+ priv aes-128 \S+ localizedkey/.match(s)
   # puts "line: #{line}"
   refute(line.nil?)
   snmpuser.destroy
  end

 def test_snmpuser_create_with_single_group_auth_sha_priv_aes128_pw_localized
   name = "userv3testauth"
   groups = []
   groups << "network-admin"
   auth_pw = "0xfe6cf9aea159c2c38e0a79ec23ed3cbb"
   priv_pw = "0xfe6cf9aea159c2c38e0a79ec23ed3cbb"
   snmpuser = SnmpUser.new(name,
                           groups,
                           :sha, auth_pw,
                           :aes128, priv_pw,
                           true, # localized
                           "")
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   line = /snmp-server user #{name} network-admin auth sha #{auth_pw} priv aes-128 #{priv_pw} localizedkey/.match(s)
   # puts "line: #{line}"
   refute(line.nil?)
   snmpuser.destroy
 end

 def test_snmpuser_create_destroy_with_engine_id
   name = "test_with_engine_id"
   auth_pw = "testpassword"
   priv_pw = "testpassword"
   engine_id = "128:12:12:12:12"
   snmpuser = SnmpUser.new(name, [""], :md5, auth_pw, :des, priv_pw,
                           false, engine_id)
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   line = /snmp-server user #{name} auth \S+ \S+ priv .*\S+ localizedkey engineID #{engine_id}/.match(s)
   refute(line.nil?)
   user = SnmpUser.users["#{name} #{engine_id}"]
   refute(user.nil?)
   assert_equal(snmpuser.name, user.name)
   assert_equal(snmpuser.name, name)
   assert_equal(snmpuser.engine_id, engine_id)
   assert_equal(snmpuser.engine_id, user.engine_id)
   snmpuser.destroy
   s = @device.cmd("show run snmp all | in #{name} | no-more")
   line = /snmp-server user #{name} auth \S+ \S+ priv .*\S+ localizedkey engineID #{engine_id}/.match(s)
   assert(line.nil?)
   assert(SnmpUser.users["#{name} #{engine_id}"].nil?)
 end

 def test_snmpuser_authpassword
   name = "test_authpassword"
   auth_pw = "0x123456"
   snmpuser = SnmpUser.new(name, [""], :md5, auth_pw, :none, "", true, "")

   pw = snmpuser.auth_password
   assert_equal(auth_pw, pw)
   snmpuser.destroy
 end

 def test_snmpuser_authpassword_with_engineid
   name = "test_authpassword"
   auth_pw = "0x123456"
   engine_id = "128:12:12:12:12"
   snmpuser = SnmpUser.new(name, [""], :md5, auth_pw, :none, "", true, engine_id)

   pw = snmpuser.auth_password
   assert_equal(auth_pw, pw)
   snmpuser.destroy
 end

 def test_snmpuser_privpassword
   name = "test_privpassword"
   priv_password = "0x123456"
   snmpuser = SnmpUser.new(name, [""], :md5, priv_password, :des, priv_password,
                           true, "")

   pw = snmpuser.priv_password
   assert_equal(priv_password, pw)
   snmpuser.destroy

   snmpuser = SnmpUser.new(name, [""], :md5, priv_password, :aes128, priv_password,
                          true, "")
   pw = snmpuser.priv_password
   assert_equal(priv_password, pw)
   snmpuser.destroy
 end

 def test_snmpuser_privpassword_with_engineid
   name = "test_privpassword"
   priv_password = "0x123456"
   engine_id = "128:12:12:12:12"
   snmpuser = SnmpUser.new(name, [""], :md5, priv_password, :des, priv_password,
                           true, engine_id)
   pw = snmpuser.priv_password
   assert_equal(priv_password, pw)
   snmpuser.destroy

   snmpuser = SnmpUser.new(name, [""], :md5, priv_password, :aes128, priv_password,
                           true, "")
   pw = snmpuser.priv_password
   assert_equal(priv_password, pw)
   snmpuser.destroy
 end

 def test_snmpuser_auth_password_equal_with_engineid
   name = "test_authpass_equal"
   auth_pass = "testpassword"
   engine_id = "128:12:12:12:12"

   snmpuser = SnmpUser.new(name, [""], :md5, auth_pass, :none, "", false,
                           engine_id)

   assert(snmpuser.auth_password_equal?(auth_pass, false))
   # our api should be able to detect wrong password
   refute(snmpuser.auth_password_equal?("test2468", false))
   snmpuser.destroy
 end

 def test_snmpuser_priv_password_equal_with_engineid
   name = "test_privpass_equal"
   priv_pass = "testpassword"
   engine_id = "128:12:12:12:12"

   snmpuser = SnmpUser.new(name, [""], :md5, priv_pass, :des, priv_pass, false,
                           engine_id)
   assert(snmpuser.priv_password_equal?(priv_pass, false))
   refute(snmpuser.priv_password_equal?("test2468", false))
   snmpuser.destroy

   snmpuser = SnmpUser.new(name, [""], :md5, priv_pass, :aes128, priv_pass, false,
                           engine_id)
   assert(snmpuser.priv_password_equal?(priv_pass, false))
   refute(false, snmpuser.priv_password_equal?("test2468", false))
   snmpuser.destroy
 end

 def test_snmpuser_default_groups
   groups = [DEFAULT_SNMP_USER_GROUP_NAME]
   assert_equal(groups, SnmpUser.default_groups(),
                "Error: Wrong default groups")
 end

 def test_snmpuser_default_auth_protocol
   assert_equal(:md5,
                SnmpUser.default_auth_protocol(),
                "Error: Wrong default auth protocol")
 end

 def test_snmpuser_default_auth_password
   assert_equal(DEFAULT_SNMP_USER_AUTH_PASSWORD,
                SnmpUser.default_auth_password(),
                "Error: Wrong default auth password")
 end

 def test_snmpuser_default_priv_protocol
   assert_equal(:des,
                SnmpUser.default_priv_protocol(),
                "Error: Wrong default priv protocol")
 end

 def test_snmpuser_default_priv_password
   assert_equal(DEFAULT_SNMP_USER_PRIV_PASSWORD,
                SnmpUser.default_priv_password(),
                "Error: Wrong default priv password")
 end
end
