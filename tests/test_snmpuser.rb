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
  @skip_unless_supported = 'snmp_user'

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

  def user_pat(name, group='network-admin', version='')
    if group
      if !version.empty?
        /snmp-server user #{name} #{group} #{version}/
      else
        /snmp-server user #{name} #{group}/
      end
    else
      /snmp-server user #{name}/
    end
  end

  # test cases starts here

  def test_collection_not_empty
    create_user('tester')
    refute_empty(SnmpUser.users,
                 'SnmpUser collection is empty')
  end

  def test_create_invalid_args
    args_list = [
      ['Empty name',
       ['', ['network-admin'],
        :none, '', :none, '', false, '', true, :v3],
      ],
      ['Auth password but no authproto',
       ['userv3testUnknownAuth', ['network-admin'],
        :none, 'test12345', :none, '', false, '', true, :v3],
      ],
      ['Priv password but no privproto',
       ['userv3testUnknownPriv', ['network-admin'],
        :sha, 'test12345', :none, 'test12345', false, '', true, :v3],
      ],
    ]
    args_list.each do |msg, args|
      assert_raises(ArgumentError, msg) { SnmpUser.new(*args) }
    end
  end

  def test_create_invalid_cli
    skip if platform == :ios_xr

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
    skip if platform == :ios_xr

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

  def test_noauth_nopriv
    name = 'userv3test2'
    groups = ['network-admin']
    snmpuser = SnmpUser.new(name,
                            groups,
                            :none, '',
                            :none, '',
                            false,
                            '',
                            true,
                            :v1)

    if platform == :ios_xr
      assert_show_match(pattern: user_pat(name),
                        command: 'show running-config snmp-server')
    else
      assert_show_match(pattern: user_pat(name),
                        command: 'show run snmp all | no-more')
    end
    snmpuser.destroy
  end

  def test_noauth_nopriv_multi
    skip if platform == :ios_xr

    name = 'userv3test3'
    groups = ['network-admin', 'vdc-admin']
    snmpuser = SnmpUser.new(name,
                            groups,
                            :none, '',
                            :none, '',
                            false,
                            '',
                            true,
                            :v1)
    s = @device.cmd('show run snmp all | no-more')
    groups.each do |group|
      assert_match(user_pat(name, group), s)
    end
    snmpuser.destroy
  end

  def test_destroy
    name = 'userv3testdestroy'
    group = 'network-operator'
    version = 'v3'

    if platform == :ios_xr
      create_user(name, "#{group} #{version}")
    else
      create_user(name, group)
    end

    # get user
    snmpuser = SnmpUser.users[name]
    assert_equal(snmpuser.name, name)
    assert_empty(snmpuser.engine_id)
    # destroy the user
    destroy_user(snmpuser)
    # check user got removed.
    sleep(5)
    node.cache_flush

    if platform == :ios_xr
      cmd = 'show running-config snmp-server'
    else
      cmd = 'show run snmp all | no-more'
    end
    refute_show_match(command: cmd,
                      pattern: user_pat(name, group))
    assert_nil(SnmpUser.users[name])
  end

  def test_auth_pw_equal_invalid_param
    skip if platform == :ios_xr

    name = 'testV3PwEqualInvalid2'
    auth_pw = 'TeSt297534'
    create_user(name, "network-admin auth md5 #{auth_pw}")

    # get users
    refute(SnmpUser.users[name].auth_password_equal?('', false))
  end

  def test_auth_priv_pw_equal_invalid_param
    skip if platform == :ios_xr

    name = 'testV3PwEqualInvalid'
    auth_pw = 'XXWWPass0wrf'
    create_user(name, "network-admin auth md5 #{auth_pw} priv #{auth_pw}")

    # get users
    snmpuser = SnmpUser.users[name]
    refute(snmpuser.auth_password_equal?('', false))
    refute(snmpuser.priv_password_equal?('', false))
  end

  def test_auth_pw_equal_priv_invalid_param
    skip if platform == :ios_xr

    name = 'testV3PwEqualInvalid'
    auth_pw = 'XXWWPass0wrf'
    create_user(name, "network-operator auth md5 #{auth_pw} priv #{auth_pw}")

    # get users
    snmpuser = SnmpUser.users[name]
    assert(snmpuser.auth_password_equal?(auth_pw, false))
    refute(snmpuser.priv_password_equal?('', false))
  end

  def test_auth_pw_not_equal
    skip if platform == :ios_xr

    name = 'testV3PwEqual'
    auth_pw = 'xxwwpass0r!f'
    create_user(name, "network-admin auth md5 #{auth_pw}")

    # get users
    snmpuser = SnmpUser.users[name]
    refute(snmpuser.auth_password_equal?('xxwwpass0r!', false))
  end

  def test_auth_pw_equal
    skip if platform == :ios_xr

    name = 'testV3PwEqual'
    auth_pw = 'XXWWPass0wrf'
    create_user(name, "network-admin auth md5 #{auth_pw}")

    # get users
    assert(SnmpUser.users[name].auth_password_equal?(auth_pw, false))
  end

  def test_auth_priv_pw_equal_empty
    skip if platform == :ios_xr

    name = 'testV3PwEmpty'
    create_user(name, 'network-admin')
    # nil and "" are treated interchangeably
    assert(SnmpUser.users[name].auth_password_equal?('', false))
    assert(SnmpUser.users[name].priv_password_equal?('', false))
    assert(SnmpUser.users[name].auth_password_equal?(nil, false))
    assert(SnmpUser.users[name].priv_password_equal?(nil, false))
  end

  def test_auth_pw_equal_localizedkey
    skip if platform == :ios_xr

    name = 'testV3PwEqual'
    auth_pw = '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    create_user(name, "network-admin auth md5 #{auth_pw} localizedkey")

    # get users
    snmpuser = SnmpUser.users[name]
    assert(snmpuser.auth_password_equal?(auth_pw, true))
    # verify that if we give a wrong password, the api will return false
    refute(snmpuser.auth_password_equal?('0xFe6c', true))
  end

  def test_auth_priv_pw_equal_localizedkey
    skip if platform == :ios_xr

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

  def test_auth_priv_des_pw_equal
    skip if platform == :ios_xr

    name = 'testV3PwEqual'
    auth_pw = 'XXWWPass0wrf'
    priv_pw = 'WWXXPaas0wrf'
    create_user(name, "network-operator auth md5 #{auth_pw} priv #{priv_pw}")

    # get users
    snmpuser = SnmpUser.users[name]
    assert(snmpuser.auth_password_equal?(auth_pw, false))
    assert(snmpuser.priv_password_equal?(priv_pw, false))
  end

  def test_auth_md5_nopriv
    skip if platform == :ios_xr

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

  def test_auth_md5_nopriv_pw_localized
    name = 'userv3testauth'
    groups = ['network-admin']
    auth_pw = platform == :ios_xr ? '152A333B331A2A373B63223015' : '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :md5, auth_pw,
                            :none, '',
                            true, # localized
                            '',
                            true,
                            :v3)
    assert_equal(snmpuser.name, name)
    assert_empty(snmpuser.engine_id)

    if platform == :ios_xr
      pat = "#{user_pat(name, groups[0], 'v3')} auth md5 encrypted 152A333B331A2A373B63223015"
      cmd = 'show running-config snmp-server'
    else
      pat = "#{user_pat(name)} auth md5 #{auth_pw} localizedkey"
      cmd = "show run snmp all | in #{name} | no-more"
    end

    assert_show_match(
      pattern: /#{pat}/,
      command: cmd)
    snmpuser.destroy
  end

  def test_auth_sha_nopriv
    skip if platform == :ios_xr

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
  def test_auth_sha_nopriv_pw_localized_false
    skip if platform == :ios_xr

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

  def test_auth_sha_nopriv_pw_localized
    name = 'userv3testauthsha4'
    groups = ['network-admin']
    auth_pw = platform == :ios_xr ? '152A333B331A2A373B63223015' : '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :sha, auth_pw,
                            :none, '',
                            true, # localized
                            '',
                            true,
                            :v3)

    if platform == :ios_xr
      pat = "#{user_pat(name, groups[0], 'v3')} auth sha encrypted 152A333B331A2A373B63223015"
      cmd = 'show running-config snmp-server'
    else
      pat = "#{user_pat(name)} auth sha #{auth_pw} localizedkey"
      cmd = "show run snmp all | in #{name} | no-more"
    end

    assert_show_match(
      pattern: /#{pat}/,
      command: cmd)
    snmpuser.destroy
  end

  def test_auth_md5_priv_des
    skip if platform == :ios_xr

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

  def test_auth_md5_priv_des_pw_localized
    name = 'userv3testauth'
    groups = ['network-admin']
    auth_pw = platform == :ios_xr ? '0307530A080824414B' : '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    priv_pw = platform == :ios_xr ? '12491D42475E5A' : '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :md5, auth_pw,
                            :des, priv_pw,
                            true, # localized
                            '',
                            true,
                            :v3)

    if platform == :ios_xr
      pat = "#{user_pat(name, groups[0], 'v3')} auth md5 encrypted #{auth_pw} priv des56 encrypted #{priv_pw}"
      cmd = 'show running-config snmp-server'
    else
      pat = "#{user_pat(name)} auth md5 #{auth_pw} priv #{priv_pw} localizedkey"
      cmd = "show run snmp all | in #{name} | no-more"
    end

    assert_show_match(
      pattern: /#{pat}/,
      command: cmd)

    snmpuser.destroy
  end

  def test_auth_md5_priv_aes128
    skip if platform == :ios_xr

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

  def test_auth_md5_priv_aes128_pw_localized
    name = 'userv3testauth'
    groups = ['network-admin']
    auth_pw = platform == :ios_xr ? '0307530A080824414B' : '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    priv_pw = platform == :ios_xr ? '12491D42475E5A' : '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :md5, auth_pw,
                            :aes128, priv_pw,
                            true, # localized
                            '',
                            true,
                            :v3)

    if platform == :ios_xr
      pat = "#{user_pat(name, groups[0], 'v3')} auth md5 encrypted #{auth_pw} priv aes 128 encrypted #{priv_pw}"
      cmd = 'show running-config snmp-server'
    else
      pat = "#{user_pat(name)} auth md5 #{auth_pw} priv aes-128 #{priv_pw} localizedkey"
      cmd = "show run snmp all | in #{name} | no-more"
    end

    assert_show_match(
      pattern: /#{pat}/,
      command: cmd)

    snmpuser.destroy
  end

  def test_auth_sha_priv_des
    skip if platform == :ios_xr

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

  def test_auth_md5_priv_sha_pw_localized
    name = 'userv3testauth'
    groups = ['network-admin']
    auth_pw = platform == :ios_xr ? '0307530A080824414B' : '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    priv_pw = platform == :ios_xr ? '12491D42475E5A' : '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :sha, auth_pw,
                            :des, priv_pw,
                            true, # localized
                            '',
                            true,
                            :v3)

    if platform == :ios_xr
      pat = "#{user_pat(name, groups[0], 'v3')} auth sha encrypted #{auth_pw} priv des56 encrypted #{priv_pw}"
      cmd = 'show running-config snmp-server'
    else
      pat = "#{user_pat(name)} auth sha #{auth_pw} priv #{priv_pw} localizedkey"
      cmd = "show run snmp all | in #{name} | no-more"
    end

    assert_show_match(
      pattern: /#{pat}/,
      command: cmd)

    snmpuser.destroy
  end

  def test_auth_sha_priv_aes128
    skip if platform == :ios_xr

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

  def test_auth_sha_priv_aes128_pw_localized
    name = 'userv3testauth'
    groups = ['network-admin']
    auth_pw = platform == :ios_xr ? '0307530A080824414B' : '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    priv_pw = platform == :ios_xr ? '12491D42475E5A' : '0xfe6cf9aea159c2c38e0a79ec23ed3cbb'
    snmpuser = SnmpUser.new(name,
                            groups,
                            :sha, auth_pw,
                            :aes128, priv_pw,
                            true, # localized
                            '',
                            true,
                            :v3)

    if platform == :ios_xr
      pat = "#{user_pat(name, groups[0], 'v3')} auth sha encrypted #{auth_pw} priv aes 128 encrypted #{priv_pw}"
      cmd = 'show running-config snmp-server'
    else
      pat = "#{user_pat(name)} auth sha #{auth_pw} priv aes-128 #{priv_pw} localizedkey"
      cmd = "show run snmp all | in #{name} | no-more"
    end

    assert_show_match(
      pattern: /#{pat}/,
      command: cmd)

    snmpuser.destroy
  end

  def test_create_destroy_with_engine_id
    skip if platform == :ios_xr

    name = 'test_with_engine_id'
    auth_pw = 'XXWWPass0wrf'
    priv_pw = 'XXWWPass0wrf'
    engine_id = '128:12:12:12:12'
    snmpuser = SnmpUser.new(name, [''], :md5, auth_pw, :des, priv_pw,
                            false, engine_id)

    assert_show_match(
      pattern: /snmp-server user #{name} auth \S+ \S+ priv .*\S+ localizedkey engineID #{engine_id}/,
      command: "show run snmp all | in #{name} | no-more")

    user = SnmpUser.users["#{name} #{engine_id}"]
    refute_nil(user)
    assert_equal(snmpuser.name, user.name)
    assert_equal(snmpuser.name, name)
    assert_equal(snmpuser.engine_id, engine_id)
    assert_equal(snmpuser.engine_id, user.engine_id)
    snmpuser.destroy

    refute_show_match(
      pattern: /snmp-server user #{name} auth \S+ \S+ priv .*\S+ localizedkey engineID #{engine_id}/,
      command: "show run snmp all | in #{name} | no-more")

    assert_nil(SnmpUser.users["#{name} #{engine_id}"])
  end

  def test_authpassword
    name = 'test_authpassword'
    auth_pw = platform == :ios_xr ? '0307530A080824414B' : '0x123456'
    group = platform == :ios_xr ? 'network-operator' : ''
    snmpuser = SnmpUser.new(name, [group], :md5, auth_pw, :none, '', true, '', true, :v3)

    pw = snmpuser.auth_password
    assert_equal(auth_pw, pw)
    snmpuser.destroy
  end

  def test_authpassword_with_engineid
    skip if platform == :ios_xr

    name = 'test_authpassword'
    auth_pw = '0x123456'
    engine_id = '128:12:12:12:12'
    snmpuser = SnmpUser.new(name, [''], :md5, auth_pw,
                            :none, '', true, engine_id)

    pw = snmpuser.auth_password
    assert_equal(auth_pw, pw)
    snmpuser.destroy
  end

  def test_privpassword
    name = 'test_privpassword'
    priv_password = platform == :ios_xr ? '12491D42475E5A' : '0x123456'
    group = platform == :ios_xr ? 'network-operator' : ''

    snmpuser = SnmpUser.new(name, [group], :md5, priv_password,
                            :des, priv_password, true, '', true, :v3)

    pw = snmpuser.priv_password
    assert_equal(priv_password, pw)
    snmpuser.destroy

    snmpuser = SnmpUser.new(name, [group], :md5, priv_password,
                            :aes128, priv_password, true, '', true, :v3)
    pw = snmpuser.priv_password
    assert_equal(priv_password, pw)
    snmpuser.destroy
  end

  def test_privpassword_with_engineid
    skip if platform == :ios_xr

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

  def test_auth_password_equal_with_engineid
    skip if platform == :ios_xr

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

  def test_priv_password_equal_with_engineid
    skip if platform == :ios_xr

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

  def test_default_groups
    groups = [DEFAULT_SNMP_USER_GROUP_NAME]
    assert_equal(groups, SnmpUser.default_groups,
                 'Error: Wrong default groups')
  end

  def test_default_auth_protocol
    assert_equal(:md5,
                 SnmpUser.default_auth_protocol,
                 'Error: Wrong default auth protocol')
  end

  def test_default_auth_password
    assert_equal(DEFAULT_SNMP_USER_AUTH_PASSWORD,
                 SnmpUser.default_auth_password,
                 'Error: Wrong default auth password')
  end

  def test_default_priv_protocol
    assert_equal(:des,
                 SnmpUser.default_priv_protocol,
                 'Error: Wrong default priv protocol')
  end

  def test_default_priv_password
    assert_equal(DEFAULT_SNMP_USER_PRIV_PASSWORD,
                 SnmpUser.default_priv_password,
                 'Error: Wrong default priv password')
  end
end
