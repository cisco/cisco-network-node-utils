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
require_relative '../lib/cisco_node_utils/tacacs_server'

# TestTacacsServer - Minitest for TacacsServer node utility
class TestTacacsServer < CiscoTestCase
  @skip_unless_supported = 'tacacs_server'

  def assert_tacacsserver_feature
    assert_show_match(command: 'show run all | no-more',
                      pattern: /feature tacacs\+/) if platform == :nexus
  end

  def refute_tacacsserver_feature
    refute_show_match(command: 'show run all | no-more',
                      pattern: /feature tacacs\+/) if platform == :nexus
  end

  def setup
    super
    if platform == :nexus
      # Most commands appear under 'show run tacacs all' but the
      # 'directed-request' command is under 'show run aaa all'
      @default_show_command = 'show run tacacs all | no-more ; ' \
                              'show run aaa all | no-more'
      config_no_warn('no feature tacacs+')

    elsif platform == :ios_xr
      @default_show_command = 'show running-config tacacs-server'
      no_tacacs_global
    end
  end

  def teardown
    config_no_warn('no feature tacacs+') if platform == :nexus
    super
  end

  def no_tacacs_global
    # Turn the feature off for a clean test.
    config('no tacacs-server timeout 2')
  end

  def test_create_valid
    tacacs = TacacsServer.new
    assert_tacacsserver_feature
    tacacs.destroy
  end

  def test_get_encryption_type
    if platform == :nexus
      config_no_warn('feature tacacs+')

      # The tacacs-server key is 'sticky'.
      # If a key is configured it will remain configured even if
      # the tacacs feature is disabled so to be safe go ahead
      # and remove any key that might exist before the test.d
      config_no_warn('no tacacs-server key')

      encryption_type = TACACS_SERVER_ENC_UNKNOWN
      # Get encryption password when not configured
      tacacs = TacacsServer.new
      assert_equal(encryption_type,
                   tacacs.encryption_type,
                   'Error: Tacacs Server, encryption type incorrect')
      tacacs.destroy

      # Get encryption password when configured
      encryption_type = TACACS_SERVER_ENC_NONE
      # This one is needed since the 'sh run' will always display the type
      # differently than the used encryption config type.
      sh_run_encryption_type = TACACS_SERVER_ENC_CISCO_TYPE_7
      config('feature tacacs+', "tacacs-server key #{encryption_type} TEST")

      tacacs = TacacsServer.new
      assert_equal(sh_run_encryption_type,
                   tacacs.encryption_type,
                   'Error: Tacacs Server, encryption type incorrect')

      encryption_type = TACACS_SERVER_ENC_CISCO_TYPE_7
      config("tacacs-server key #{encryption_type} TEST")

      assert_equal(sh_run_encryption_type,
                   tacacs.encryption_type,
                   'Error: Tacacs Server, encryption type incorrect')
      tacacs.destroy
    elsif platform == :ios_xr
      encryption_type = TACACS_SERVER_ENC_NONE
      sh_run_encryption_type = TACACS_SERVER_ENC_CISCO_TYPE_7
      config("tacacs-server key #{encryption_type} TEST")

      tacacs = TacacsServer.new
      assert_equal(sh_run_encryption_type,
                   tacacs.encryption_type,
                   'Error: Tacacs Server, encryption type incorrect')
      tacacs.destroy
    end
  end

  def test_get_default_encryption
    # Ruby can use defines, but only they're not initialized from an enum
    assert_equal(TACACS_SERVER_ENC_NONE,
                 TacacsServer.default_encryption_type,
                 'Error: Tacacs Server, default encryption incorrect')
  end

  def test_get_encryption_password
    config('no tacacs-server key') if platform == :ios_xr

    tacacs = TacacsServer.new
    assert_equal(node.config_get_default('tacacs_server',
                                         'encryption_password'),
                 tacacs.encryption_password,
                 'Error: Tacacs Server, encryption password incorrect')
    tacacs.destroy

    # Get encryption password when configured
    sh_run_encryption_password = 'WAWY'
    encryption_type = TACACS_SERVER_ENC_NONE
    # This one is needed since the 'sh run' will always display the password
    # differently than the used encryption config type.
    if platform == :nexus
      config('feature tacacs+', "tacacs-server key #{encryption_type} TEST")
    elsif platform == :ios_xr
      config("tacacs-server key #{encryption_type} TEST")
    end
    tacacs = TacacsServer.new

    if platform == :nexus
      assert_match(/#{sh_run_encryption_password}/,
                   tacacs.encryption_password,
                   'Error: Tacacs Server, encryption password incorrect')
    elsif platform == :ios_xr
      # When a password is set on ios_xr it is always encrypted,
      # even as a return value, hence here checking for not nil.
      assert(!tacacs.encryption_password.nil?)
    end

    tacacs.destroy
  end

  def test_get_default_encryption_password
    assert_equal(node.config_get_default('tacacs_server',
                                         'encryption_password'),
                 TacacsServer.default_encryption_password,
                 'Error: Tacacs Server, default encryption password incorrect')
  end

  def test_key_set
    enc_type = TACACS_SERVER_ENC_NONE
    # This one is needed since the 'sh run' will always display the type
    # differently than the used encryption config type.
    sh_run_encryption_type = TACACS_SERVER_ENC_CISCO_TYPE_7
    password = 'TEST_NEW'

    tacacs = TacacsServer.new
    tacacs.encryption_key_set(enc_type, password)
    # Get the password from the running config since its encoded
    if platform == :nexus
      line = assert_show_match(
        pattern: /tacacs-server key\s#{sh_run_encryption_type}\s".*"/,
        msg:     'Error: Tacacs Server, key not configured')
    elsif platform == :ios_xr
      line = assert_show_match(
        pattern: /tacacs-server key\s#{sh_run_encryption_type}\s.*/,
        msg:     'Error: Tacacs Server, key not configured')
    end
    # Extract encrypted password, and git rid of the "" around the pasword
    md = line.to_s
    encrypted_password = md.to_s.split(' ').last.tr('\"', '')
    # Extract encryption type
    md = /tacacs-server\skey\s\d/.match(line.to_s)
    encrypted_type = md.to_s.split(' ').last.to_i
    assert_equal(encrypted_type, tacacs.encryption_type,
                 'Error: Tacacs Server, encryption type incorrect')
    assert_match(/#{encrypted_password}/, tacacs.encryption_password,
                 'Error: Tacacs Server, encryption password incorrect')
    tacacs.destroy
  end

  def test_key_unconfigure
    enc_type = TACACS_SERVER_ENC_NONE
    # This one is needed since the 'sh run' will always display the type
    # differently than the used encryption config type.
    sh_run_encryption_type = TACACS_SERVER_ENC_CISCO_TYPE_7
    password = 'TEST_NEW'

    tacacs = TacacsServer.new
    tacacs.encryption_key_set(enc_type, password)
    if platform == :nexus
      assert_show_match(
        pattern: /tacacs-server key\s#{sh_run_encryption_type}\s".*"/,
        msg:     'Error: Tacacs Server, key not configured')
    elsif platform == :ios_xr
      assert_show_match(
        pattern: /tacacs-server key\s#{sh_run_encryption_type}\s.*/,
        msg:     'Error: Tacacs Server, key not configured')
    end
    enc_type = TACACS_SERVER_ENC_UNKNOWN
    password = ''
    tacacs.encryption_key_set(enc_type, password)
    if platform == :nexus
      refute_show_match(
        pattern: /tacacs-server key\s#{sh_run_encryption_type}\s".*"/,
        msg:     'Error: Tacacs Server, key configured')
    elsif platform == :ios_xr
      refute_show_match(
        pattern: /tacacs-server key\s#{sh_run_encryption_type}\s.*/,
        msg:     'Error: Tacacs Server, key configured')
    end
    tacacs.destroy
  end

  def test_get_timeout
    tacacs = TacacsServer.new
    timeout = node.config_get_default('tacacs_server', 'timeout')
    assert_equal(timeout, tacacs.timeout,
                 'Error: Tacacs Server, timeout not default')

    timeout = 35
    config("tacacs-server timeout #{timeout}")
    assert_equal(timeout, tacacs.timeout,
                 'Error: Tacacs Server, timeout not configured')
    tacacs.destroy
  end

  def test_get_default_timeout
    assert_equal(node.config_get_default('tacacs_server', 'timeout'),
                 TacacsServer.default_timeout,
                 'Error: Tacacs Server, default timeout incorrect')
  end

  def test_set_timeout
    timeout = 45

    tacacs = TacacsServer.new
    tacacs.timeout = timeout
    line = assert_show_match(pattern: /tacacs-server timeout\s.*/,
                             msg:     'Error: timeout not configured')
    # Extract timeout
    md = /tacacs-server\stimeout\s\d*/.match(line.to_s)
    sh_run_timeout = md.to_s.split(' ').last.to_i
    # Need a better way to extract the timeout
    assert_equal(sh_run_timeout, tacacs.timeout,
                 'Error: Tacacs Server, timeout value incorrect')

    # Invalid case
    timeout = 80 if platform == :nexus
    timeout = 80_000 if platform == :ios_xr

    assert_raises(Cisco::CliError) do
      tacacs.timeout = timeout
    end
    tacacs.destroy
  end

  def test_get_deadtime
    return if validate_property_excluded?('tacacs_server', 'deadtime')

    tacacs = TacacsServer.new
    deadtime = node.config_get_default('tacacs_server', 'deadtime')
    assert_equal(deadtime, tacacs.deadtime,
                 'Error: Tacacs Server, deadtime not default')

    deadtime = 850
    config("tacacs-server deadtime #{deadtime}")
    assert_equal(deadtime, tacacs.deadtime,
                 'Error: Tacacs Server, deadtime not configured')
    tacacs.destroy
  end

  def test_get_default_deadtime
    return if validate_property_excluded?('tacacs_server', 'deadtime')

    assert_equal(node.config_get_default('tacacs_server', 'deadtime'),
                 TacacsServer.default_deadtime,
                 'Error: Tacacs Server, default deadtime incorrect')
  end

  def test_set_deadtime
    return if validate_property_excluded?('tacacs_server', 'deadtime')
    deadtime = 1250

    tacacs = TacacsServer.new
    tacacs.deadtime = deadtime
    line = assert_show_match(pattern: /tacacs-server deadtime\s.*/,
                             msg:     'Error: deadtime not configured')
    # Extract deadtime
    md = /tacacs-server\sdeadtime\s\d*/.match(line.to_s)
    sh_run_deadtime = md.to_s.split(' ').last.to_i
    assert_equal(sh_run_deadtime, tacacs.deadtime,
                 'Error: Tacacs Server, deadtime incorrect')
    # Invalid case
    deadtime = 2450
    assert_raises(Cisco::CliError) do
      tacacs.deadtime = deadtime
    end
    tacacs.destroy
  end

  def test_get_directed_request
    return if validate_property_excluded?('tacacs_server', 'deadtime')

    config('feature tacacs', 'tacacs-server directed-request')
    tacacs = TacacsServer.new
    assert(tacacs.directed_request?,
           'Error: Tacacs Server, directed-request not set')

    config('no tacacs-server directed-request')
    refute(tacacs.directed_request?,
           'Error: Tacacs Server, directed-request set')
    tacacs.destroy
  end

  def test_get_default_directed_request
    return if validate_property_excluded?('tacacs_server', 'deadtime')
    assert_equal(node.config_get_default('tacacs_server', 'directed_request'),
                 TacacsServer.default_directed_request,
                 'Error: Tacacs Server, default directed-request incorrect')
  end

  def test_set_directed_request
    return if validate_property_excluded?('tacacs_server', 'deadtime')
    config('feature tacacs', 'tacacs-server directed-request')
    state = true
    tacacs = TacacsServer.new
    tacacs.directed_request = state
    assert_show_match(pattern: /tacacs-server directed-request/,
                      msg:     'directed-request not configured')
    assert(tacacs.directed_request?,
           'Error: Tacacs Server, directed-request not set')

    # Turn it off
    config('no tacacs-server directed-request')
    refute(tacacs.directed_request?,
           'Error: Tacacs Server, directed-request set')

    # Turn it back on then go to default
    config('no tacacs-server directed-request')
    state = node.config_get_default('tacacs_server', 'directed_request')
    tacacs.directed_request = state
    line = assert_show_match(pattern: /no tacacs-server directed-request/,
                             msg:     'default directed-request not configed')

    # Extract the state of directed-request
    sh_run_directed_request = line.to_s.split(' ').first
    assert_equal('no', sh_run_directed_request,
                 'Error: Tacacs Server, directed-request not unconfigured')

    refute(tacacs.directed_request?,
           'Error: Tacacs Server, directed-request set')

    # Invalid case
    state = 'TEST'
    assert_raises(TypeError) do
      tacacs.directed_request = state
    end
    tacacs.destroy
  end

  def test_get_source_interface
    return if validate_property_excluded?('tacacs_server', 'deadtime')

    config_no_warn('no ip tacacs source-interface')
    tacacs = TacacsServer.new
    intf = node.config_get_default('tacacs_server', 'source_interface')
    assert_equal(intf, tacacs.source_interface,
                 'Error: Tacacs Server, source-interface set')

    intf = 'loopback41'
    config("ip tacacs source-interface #{intf}")
    assert_equal(intf, tacacs.source_interface,
                 'Error: Tacacs Server, source-interface not correct')
    tacacs.destroy
  end

  def test_get_default_source_interface
    return if validate_property_excluded?('tacacs_server', 'deadtime')

    assert_equal(node.config_get_default('tacacs_server', 'source_interface'),
                 TacacsServer.default_source_interface,
                 'Error: Tacacs Server, default source-interface incorrect')
  end

  def test_set_source_interface
    return if validate_property_excluded?('tacacs_server', 'deadtime')

    config('feature tacacs+', 'no ip tacacs source-int')
    intf = node.config_get_default('tacacs_server', 'source_interface')
    tacacs = TacacsServer.new
    assert_equal(intf, tacacs.source_interface,
                 'Error: Tacacs Server, source-interface set')

    intf = 'loopback41'
    tacacs.source_interface = intf
    line = assert_show_match(pattern: /ip tacacs source-interface #{intf}/,
                             msg:     'source-interface not configured')
    # Extract source-interface
    sh_run_source_interface = line.to_s.split(' ').last
    assert_equal(sh_run_source_interface, tacacs.source_interface,
                 'Error: Tacacs Server, source-interface not correct')

    # Now bring it back to default
    intf = node.config_get_default('tacacs_server', 'source_interface')
    tacacs.source_interface = intf
    assert_show_match(pattern: /no ip tacacs source-interface/,
                      msg:     'source-interface not default')

    # Invalid case
    state = true
    assert_raises(TypeError) do
      tacacs.source_interface = state
    end
    tacacs.destroy
  end

  def test_destroy
    tacacs = TacacsServer.new
    assert_tacacsserver_feature
    tacacs.destroy
    refute_tacacsserver_feature
  end
end
