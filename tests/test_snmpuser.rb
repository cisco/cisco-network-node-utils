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
require_relative '../lib/cisco_node_utils/snmpuser'

DEFAULT_SNMP_USER_AUTH_PASSWORD = ''
DEFAULT_SNMP_USER_PRIV_PASSWORD = ''
DEFAULT_SNMP_USER_GROUP_NAME = 'network-operator'

# TestSnmpUser - Minitest for SnmpUser node utility class
class TestSnmpUser < CiscoTestCase
  @@existing_users = nil # rubocop:disable Style/ClassVars

  def setup
    super
    @test_users = []
    # Get the list of users that exist on the node when we first begin
    @@existing_users ||= SnmpUser.users.keys # rubocop:disable Style/ClassVars
  end

  def create_user(name, opts='')
    config("snmp-server user #{name} #{opts}")
    @test_users.push(name)
  end

  def destroy_user(user)
    @test_users.delete(user.name)
    user.destroy
  end

  def teardown
    unless @test_users.empty?
      cfg = @test_users.collect { |name| "no snmp-server user #{name}" }
      config(*cfg)
    end
    super
    delta = SnmpUser.users.keys - @@existing_users
    # User deletion can take some time, for some reason
    unless delta.empty?
      sleep(5)
      node.cache_flush
      delta = SnmpUser.users.keys - @@existing_users
    end
    @@existing_users = SnmpUser.users.keys # rubocop:disable Style/ClassVars
    assert_empty(delta, 'Users not deleted after test!')
  end

  def user_pat(name, group='network-admin')
    group ? /snmp-server user #{name} #{group}/ : /snmp-server user #{name}/
  end

  ## test cases starts here

  def test_snmpuser_collection_not_empty
    create_user('tester')
    refute_empty(SnmpUser.users,
                 'SnmpUser collection is empty')
  end

  def test_snmpuser_create_invalid_args
    args_list = [
      ['Empty name',
       ['', ['network-admin'],
        :none, '', :none, '', false, ''],
      ],
      ['Auth password but no authproto',
       ['userv3testUnknownAuth', ['network-admin'],
        :none, 'test12345', :none, '', false, ''],
      ],
      ['Priv password but no privproto',
       ['userv3testUnknownPriv', ['network-admin'],
        :sha, 'test12345', :none, 'test12345', false, ''],
      ],
    ]
    args_list.each do |msg, args|
      assert_raises(ArgumentError, msg) { SnmpUser.new(*args) }
    end
  end

  def test_snmpuser_create_invalid_cli
    args_list = [
      ['Cleartext password with localized key',
       ['userv3testauthsha1', ['network-admin'],
        :sha, 'test123456', :none, '', true, # localized key
        ''],
      ],
      ['NX-OS Password must be at least 8 characters',
       ['userv3testauthsha2', ['network-admin'],
        :sha, 'test', :none, '', false, ''],
      ],
      ['Invalid group name',
       ['userv3test', ['network-admin123'],
        :none, '', :none, '', false, ''],
      ],
    ]
    args_list.each do |msg, args|
      assert_raises(CliError, msg) { SnmpUser.new(*args) }
    end
  end

  def test_engine_id_valid_and_none
    create_user('tester', 'auth sha XXWWPass0wrf engineID 22:22:22:22:23:22')
    create_user('tester2')

    snmpusers = SnmpUser.users

    found_tester = false
    found_tester2 = false
    snmpusers.each_value do |snmpuser|
      if snmpuser.name == 'tester'
        assert_equal('22:22:22:22:23:22', snmpuser.engine_id)
        destroy_user(snmpuser)
        found_tester = true
      elsif snmpuser.name == 'tester2'
        assert_equal('', snmpuser.engine_id)
        destroy_user(snmpuser)
        found_tester2 = true
      end
    end
    assert(found_tester)
    assert(found_tester2)
  end

  def test_snmpuser_create_with_single_group_noauth_nopriv
    name = 'userv3test2'
    groups = ['network-admin']
    snmpuser = SnmpUser.new(name,
                            groups,
                            :none, '',
                            :none, '',
                            false,
                            '')
    assert_show_match(pattern: user_pat(name),
                      command: 'show run snmp all | no-more')
    snmpuser.destroy
  end

  def test_snmpuser_create_with_multi_group_noauth_nopriv
    name = 'userv3test3'
    groups = ['network-admin', 'vdc-admin']
    snmpuser = SnmpUser.new(name,
                            groups,
                            :none, '',
                            :none, '',
                            false,
                            '')
    s = @device.cmd('show run snmp all | no-more')
    groups.each do |group|
      assert_match(user_pat(name, group), s)
    end
    snmpuser.destroy
  end

  def test_snmpuser_destroy
    name = 'userv3testdestroy'
    group = 'network-operator'
    create_user(name, group)

    # get user
    snmpuser = SnmpUser.users[name]
    assert_equal(snmpuser.name, name)
    assert_empty(snmpuser.engine_id)
    # destroy the user
    destroy_user(snmpuser)
    # check user got removed.
    sleep(5)
    node.cache_flush
    refute_show_match(command: 'show run snmp all | no-more',
                      pattern: user_pat(name, group))
    assert_nil(SnmpUser.users[name])
  end

  def test_snmpuser_auth_password_equal_invalid_param
    name = 'testV3PwEqualInvalid2'
    auth_pw = 'TeSt297534'
    create_user(name, "network-admin auth md5 #{auth_pw}")

    # get users
    refute(SnmpUser.users[name].auth_password_equal?('', false))
  end

  def test_snmpuser_auth_priv_password_equal_invalid_param
    name = 'testV3PwEqualInvalid'
    auth_pw = 'XXWWPass0wrf'
    create_user(name, "network-admin auth md5 #{auth_pw} priv #{auth_pw}")

    # get users
    snmpuser = SnmpUser.users[name]
    refute(snmpuser.auth_password_equal?('', false))
    refute(snmpuser.priv_password_equal?('', false))
  end

  def test_snmpuser_auth_password_equal_priv_invalid_param
    name = 'testV3PwEqualInvalid'
    auth_pw = 'XXWWPass0wrf'
    create_user(name, "network-operator auth md5 #{auth_pw} priv #{auth_pw}")

    # get users
    snmpuser = SnmpUser.users[name]
    assert(snmpuser.auth_password_equal?(auth_pw, false))
    refute(snmpuser.priv_password_equal?('', false))
  end

  def test_snmpuser_auth_password_not_equal
    name = 'testV3PwEqual'
    auth_pw = 'xxwwpass0r!f'
    create_user(name, "network-admin auth md5 #{auth_pw}")

    # get users
    snmpuser = SnmpUser.users[name]
    refute(snmpuser.auth_password_equal?('xxwwpass0r!', false))
  end

  def test_snmpuser_auth_password_equal
    name = 'testV3PwEqual'
    auth_pw = 'XXWWPass0wrf'
    create_user(name, "network-admin auth md5 #{auth_pw}")

    # get users
    assert(SnmpUser.users[name].auth_password_equal?(auth_pw, false))
  end

  def test_snmpuser_auth_priv_password_equal_empty
    name = 'testV3PwEmpty'
    create_user(name, 'network-admin')
    # nil and "" are treated interchangeably
    assert(SnmpUser.users[name].auth_password_equal?('', false))
    assert(SnmpUser.users[name].priv_password_equal?('', false))
    assert(SnmpUser.users[name].auth_password_equal?(nil, false))
    assert(SnmpUser.users[name].priv_password_equal?(nil, false))
  end

  def test_snmpuser_auth_password_equal_localizedkey
    name = 'testV3PwEqual'
    auth_pw = '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    create_user(name, "network-admin auth md5 #{auth_pw} localizedkey")

    # get users
    snmpuser = SnmpUser.users[name]
    assert(snmpuser.auth_password_equal?(auth_pw, true))
    # verify that if we give a wrong password, the api will return false
    refute(snmpuser.auth_password_equal?('0xFe6c', true))
  end

  def test_snmpuser_auth_priv_password_equal_localizedkey
    name = 'testV3PwEqual'
    auth_pw = '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    priv_pw = '0x29916eac22d90362598abef1b9045018'
    create_user(name, "network-admin auth md5 #{auth_pw} " \
                "priv aes-128 #{priv_pw} localizedkey")

    # get users
    snmpuser = SnmpUser.users[name]
    assert(snmpuser.auth_password_equal?(auth_pw, true))
    assert(snmpuser.priv_password_equal?(priv_pw, true))
    refute(snmpuser.priv_password_equal?('0x2291', true))
  end

  def test_snmpuser_auth_priv_des_password_equal
    name = 'testV3PwEqual'
    auth_pw = 'XXWWPass0wrf'
    priv_pw = 'WWXXPaas0wrf'
    create_user(name, "network-operator auth md5 #{auth_pw} priv #{priv_pw}")

    # get users
    snmpuser = SnmpUser.users[name]
    assert(snmpuser.auth_password_equal?(auth_pw, false))
    assert(snmpuser.priv_password_equal?(priv_pw, false))
  end

  def test_snmpuser_create_with_single_group_auth_md5_nopriv
    name = 'userv3test5'
    groups = ['network-admin']
    auth_pw = 'XXWWPass0wrf'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :md5, auth_pw,
                            :none, '',
                            false, # clear text
                            '')
    assert_show_match(
      pattern: /#{user_pat(name)} auth md5 \S+ localizedkey/,
      command: "show run snmp all | in #{name} | no-more")
    snmpuser.destroy
  end

  def test_snmpuser_create_with_single_group_auth_md5_nopriv_pw_localized
    name = 'userv3testauth'
    groups = ['network-admin']
    auth_pw = '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :md5, auth_pw,
                            :none, '',
                            true, # localized
                            '')
    assert_equal(snmpuser.name, name)
    assert_empty(snmpuser.engine_id)
    assert_show_match(
      pattern: /#{user_pat(name)} auth md5 #{auth_pw} localizedkey/,
      command: "show run snmp all | in #{name} | no-more")
    snmpuser.destroy
  end

  def test_snmpuser_create_with_single_group_auth_sha_nopriv
    name = 'userv3testsha'
    groups = ['network-admin']
    auth_pw = 'XXWWPass0wrf'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :sha, auth_pw,
                            :none, '',
                            false, # clear text
                            '')
    assert_show_match(
      pattern: /#{user_pat(name)} auth sha \S+ localizedkey/,
      command: "show run snmp all | in #{name} | no-more")
    snmpuser.destroy
  end

  # If the auth pw is in hex and localized key param in constructor is false,
  # then the pw got localized by the device again.
  def test_create_1_group_auth_sha_nopriv_pw_localized_localizedkey_false
    name = 'userv3testauthsha3'
    groups = ['network-admin']
    auth_pw = '0xFe6cf9aea159c2c38e0a79ec23ed3cbb'

    snmpuser = SnmpUser.new(name,
                            groups,
                            :sha, auth_pw,
                            :none, '',
                            false, # localized key
                            '')
    assert_show_match(
      pattern: /#{user_pat(name)} auth sha \S+ localizedkey/,
      command: "show run snmp all | in #{name} | no-more")
    snmpuser.destroy
  end

  def test_snmpuser_create_with_single_group_auth_sha_nopriv_pw_localized
    name = 'userv3testauthsha4'
    groups = ['network-admin']
    auth_pw = '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :sha, auth_pw,
                            :none, '',
                            true, # localized
                            '')
    assert_show_match(
      pattern: /#{user_pat(name)} auth sha #{auth_pw} localizedkey/,
      command: "show run snmp all | in #{name} | no-more")
    snmpuser.destroy
  end

  def test_snmpuser_create_with_single_group_auth_md5_priv_des
    name = 'userv3test6'
    groups = ['network-admin']
    auth_pw = 'XXWWPass0wrf'
    priv_pw = 'Priv973ApQsX'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :md5, auth_pw,
                            :des, priv_pw,
                            false, # clear text
                            '')
    assert_show_match(
      pattern: /#{user_pat(name)} auth md5 \S+ priv \S+ localizedkey/,
      command: "show run snmp all | in #{name} | no-more")
    snmpuser.destroy
  end

  def test_snmpuser_create_with_single_group_auth_md5_priv_des_pw_localized
    name = 'userv3testauth'
    groups = ['network-admin']
    auth_pw = '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    priv_pw = '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :md5, auth_pw,
                            :des, priv_pw,
                            true, # localized
                            '')
    # rubocop:disable Metrics/LineLength
    assert_show_match(
      pattern: /#{user_pat(name)} auth md5 #{auth_pw} priv #{priv_pw} localizedkey/,
      command: "show run snmp all | in #{name} | no-more")
    # rubocop:enable Metrics/LineLength
    snmpuser.destroy
  end

  def test_snmpuser_create_with_single_group_auth_md5_priv_aes128
    name = 'userv3test7'
    groups = ['network-admin']
    auth_pw = 'XXWWPass0wrf'
    priv_pw = 'Priv973ApQsX'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :md5, auth_pw,
                            :aes128, priv_pw,
                            false, # clear text
                            '')
    assert_show_match(
      pattern: /#{user_pat(name)} auth md5 \S+ priv aes-128 \S+ localizedkey/,
      command: "show run snmp all | in #{name} | no-more")
    snmpuser.destroy
  end

  def test_snmpuser_create_with_single_group_auth_md5_priv_aes128_pw_localized
    name = 'userv3testauth'
    groups = ['network-admin']
    auth_pw = '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    priv_pw = '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :md5, auth_pw,
                            :aes128, priv_pw,
                            true, # localized
                            '')
    # rubocop:disable Metrics/LineLength
    assert_show_match(
      pattern: /#{user_pat(name)} auth md5 #{auth_pw} priv aes-128 #{priv_pw} localizedkey/,
      command: "show run snmp all | in #{name} | no-more")
    # rubocop:enable Metrics/LineLength
    snmpuser.destroy
  end

  def test_snmpuser_create_with_single_group_auth_sha_priv_des
    name = 'userv3test8'
    groups = ['network-admin']
    auth_pw = 'XXWWPass0wrf'
    priv_pw = 'Priv973ApQsX'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :sha, auth_pw,
                            :des, priv_pw,
                            false, # clear text
                            '')
    assert_show_match(
      pattern: /#{user_pat(name)} auth sha \S+ priv \S+ localizedkey/,
      command: "show run snmp all | in #{name} | no-more")
    snmpuser.destroy
  end

  def test_snmpuser_create_with_single_group_auth_md5_priv_sha_pw_localized
    name = 'userv3testauth'
    groups = ['network-admin']
    auth_pw = '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    priv_pw = '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :sha, auth_pw,
                            :des, priv_pw,
                            true, # localized
                            '')
    # rubocop:disable Metrics/LineLength
    assert_show_match(
      pattern: /#{user_pat(name)} auth sha #{auth_pw} priv #{priv_pw} localizedkey/,
      command: "show run snmp all | in #{name} | no-more")
    # rubocop:enable Metrics/LineLength
    snmpuser.destroy
  end

  def test_snmpuser_create_with_single_group_auth_sha_priv_aes128
    name = 'userv3test9'
    groups = ['network-admin']
    auth_pw = 'XXWWPass0wrf'
    priv_pw = 'Priv973ApQsX'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :sha, auth_pw,
                            :aes128, priv_pw,
                            false, # clear text
                            '')
    assert_show_match(
      pattern: /#{user_pat(name)} auth sha \S+ priv aes-128 \S+ localizedkey/,
      command: "show run snmp all | in #{name} | no-more")
    snmpuser.destroy
  end

  def test_snmpuser_create_with_single_group_auth_sha_priv_aes128_pw_localized
    name = 'userv3testauth'
    groups = ['network-admin']
    auth_pw = '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    priv_pw = '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :sha, auth_pw,
                            :aes128, priv_pw,
                            true, # localized
                            '')
    # rubocop:disable Metrics/LineLength
    assert_show_match(
      pattern: /#{user_pat(name)} auth sha #{auth_pw} priv aes-128 #{priv_pw} localizedkey/,
      command: "show run snmp all | in #{name} | no-more")
    # rubocop:enable Metrics/LineLength
    snmpuser.destroy
  end

  def test_snmpuser_create_destroy_with_engine_id
    name = 'test_with_engine_id'
    auth_pw = 'XXWWPass0wrf'
    priv_pw = 'XXWWPass0wrf'
    engine_id = '128:12:12:12:12'
    snmpuser = SnmpUser.new(name, [''], :md5, auth_pw, :des, priv_pw,
                            false, engine_id)
    # rubocop:disable Metrics/LineLength
    assert_show_match(
      pattern: /snmp-server user #{name} auth \S+ \S+ priv .*\S+ localizedkey engineID #{engine_id}/,
      command: "show run snmp all | in #{name} | no-more")
    # rubocop:enable Metrics/LineLength
    user = SnmpUser.users["#{name} #{engine_id}"]
    refute_nil(user)
    assert_equal(snmpuser.name, user.name)
    assert_equal(snmpuser.name, name)
    assert_equal(snmpuser.engine_id, engine_id)
    assert_equal(snmpuser.engine_id, user.engine_id)
    snmpuser.destroy
    # rubocop:disable Metrics/LineLength
    refute_show_match(
      pattern: /snmp-server user #{name} auth \S+ \S+ priv .*\S+ localizedkey engineID #{engine_id}/,
      command: "show run snmp all | in #{name} | no-more")
    # rubocop:enable Metrics/LineLength
    assert_nil(SnmpUser.users["#{name} #{engine_id}"])
  end

  def test_snmpuser_authpassword
    name = 'test_authpassword'
    auth_pw = '0x123456'
    snmpuser = SnmpUser.new(name, [''], :md5, auth_pw, :none, '', true, '')

    pw = snmpuser.auth_password
    assert_equal(auth_pw, pw)
    snmpuser.destroy
  end

  def test_snmpuser_authpassword_with_engineid
    name = 'test_authpassword'
    auth_pw = '0x123456'
    engine_id = '128:12:12:12:12'
    snmpuser = SnmpUser.new(name, [''], :md5, auth_pw,
                            :none, '', true, engine_id)

    pw = snmpuser.auth_password
    assert_equal(auth_pw, pw)
    snmpuser.destroy
  end

  def test_snmpuser_privpassword
    name = 'test_privpassword'
    priv_password = '0x123456'
    snmpuser = SnmpUser.new(name, [''], :md5, priv_password,
                            :des, priv_password, true, '')

    pw = snmpuser.priv_password
    assert_equal(priv_password, pw)
    snmpuser.destroy

    snmpuser = SnmpUser.new(name, [''], :md5, priv_password,
                            :aes128, priv_password, true, '')
    pw = snmpuser.priv_password
    assert_equal(priv_password, pw)
    snmpuser.destroy
  end

  def test_snmpuser_privpassword_with_engineid
    name = 'test_privpassword2'
    priv_password = '0x123456'
    engine_id = '128:12:12:12:12'
    snmpuser = SnmpUser.new(name, [''], :md5, priv_password,
                            :des, priv_password, true, engine_id)
    pw = snmpuser.priv_password
    assert_equal(priv_password, pw)
    snmpuser.destroy

    snmpuser = SnmpUser.new(name, [''], :md5, priv_password,
                            :aes128, priv_password, true, '')
    pw = snmpuser.priv_password
    assert_equal(priv_password, pw)
    snmpuser.destroy
  end

  def test_snmpuser_auth_password_equal_with_engineid
    name = 'test_authpass_equal'
    auth_pass = 'XXWWPass0wrf'
    engine_id = '128:12:12:12:12'

    snmpuser = SnmpUser.new(name, [''], :md5, auth_pass, :none, '', false,
                            engine_id)

    assert(snmpuser.auth_password_equal?(auth_pass, false))
    # our api should be able to detect wrong password
    refute(snmpuser.auth_password_equal?('WWXXPass0wrf', false))
    snmpuser.destroy
  end

  def test_snmpuser_priv_password_equal_with_engineid
    name = 'test_privpass_equal'
    priv_pass = 'XXWWPass0wrf'
    engine_id = '128:12:12:12:12'

    snmpuser = SnmpUser.new(name, [''], :md5, priv_pass, :des, priv_pass, false,
                            engine_id)
    assert(snmpuser.priv_password_equal?(priv_pass, false))
    refute(snmpuser.priv_password_equal?('tWWXXpass0wrf', false))
    snmpuser.destroy

    snmpuser = SnmpUser.new(name, [''], :md5, priv_pass,
                            :aes128, priv_pass, false, engine_id)
    assert(snmpuser.priv_password_equal?(priv_pass, false))
    refute(snmpuser.priv_password_equal?('tWWXXpass0wrf', false))
    snmpuser.destroy
  end

  def test_snmpuser_default_groups
    groups = [DEFAULT_SNMP_USER_GROUP_NAME]
    assert_equal(groups, SnmpUser.default_groups,
                 'Error: Wrong default groups')
  end

  def test_snmpuser_default_auth_protocol
    assert_equal(:md5,
                 SnmpUser.default_auth_protocol,
                 'Error: Wrong default auth protocol')
  end

  def test_snmpuser_default_auth_password
    assert_equal(DEFAULT_SNMP_USER_AUTH_PASSWORD,
                 SnmpUser.default_auth_password,
                 'Error: Wrong default auth password')
  end

  def test_snmpuser_default_priv_protocol
    assert_equal(:des,
                 SnmpUser.default_priv_protocol,
                 'Error: Wrong default priv protocol')
  end

  def test_snmpuser_default_priv_password
    assert_equal(DEFAULT_SNMP_USER_PRIV_PASSWORD,
                 SnmpUser.default_priv_password,
                 'Error: Wrong default priv password')
  end
end
