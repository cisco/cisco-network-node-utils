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

require File.expand_path('../ciscotest', __FILE__)
require File.expand_path('../../lib/cisco_node_utils/tacacs_server', __FILE__)

# TestTacacsServer - Minitest for TacacsServer node utility
class TestTacacsServer < CiscoTestCase
  def tacacsserver_feature
    s = @device.cmd('show run all | no-more')
    cmd = 'feature tacacs+'
    /#{cmd}/.match(s)
  end

  # Helper routine to get the tacacs config. Ideally we should be able
  # to use 'sh run tacacs all' but that does not work for 'directed-request'
  # why 'sh run aaa all' is used.
  def get_tacacsserver_match_line(name)
    s = @device.cmd('show run tacacs all | no-more ; show run aaa all | no-more')
    cmd = 'tacacs-server'
    pattern = (/#{cmd} #{name}/)
    pattern.match(s)
  end

  def get_match_line(name)
    s = @device.cmd('show run all | no-more')
    /#{name}/.match(s)
  end

  def test_tacacsserver_create_valid
    tacacs = TacacsServer.new
    line = tacacsserver_feature
    refute_nil(line, 'Error: Tacacs feature not set')
    tacacs.destroy
  end

  def test_tacacsserver_get_encryption_type
    @device.cmd('conf t ; no feature tacacs+ ; feature tacacs+ ; end')
    node.cache_flush
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
    @device.cmd('configure terminal')
    @device.cmd('feature tacacs+')
    @device.cmd("tacacs-server key #{encryption_type} TEST")
    @device.cmd('end')
    node.cache_flush

    tacacs = TacacsServer.new
    assert_equal(sh_run_encryption_type,
                 tacacs.encryption_type,
                 'Error: Tacacs Server, encryption type incorrect')

    encryption_type = TACACS_SERVER_ENC_CISCO_TYPE_7
    @device.cmd('configure terminal')
    @device.cmd("tacacs-server key #{encryption_type} TEST")
    @device.cmd('end')
    node.cache_flush

    assert_equal(sh_run_encryption_type,
                 tacacs.encryption_type,
                 'Error: Tacacs Server, encryption type incorrect')
    tacacs.destroy
  end

  def test_tacacsserver_get_default_encryption
    # Ruby can use defines, but only they're not initialized from an enum
    assert_equal(TACACS_SERVER_ENC_NONE,
                 TacacsServer.default_encryption_type,
                 'Error: Tacacs Server, default encryption incorrect')
  end

  def test_tacacsserver_get_encryption_password
    # Get encryption password when not configured
    @device.cmd('conf t ; no feature tacacs+ ; end')
    node.cache_flush
    tacacs = TacacsServer.new
    assert_equal(node.config_get_default('tacacs_server', 'encryption_password'),
                 tacacs.encryption_password,
                 'Error: Tacacs Server, encryption password incorrect')
    tacacs.destroy

    # Get encryption password when configured
    sh_run_encryption_password = 'WAWY'
    encryption_type = TACACS_SERVER_ENC_NONE
    # This one is needed since the 'sh run' will always display the password
    # differently than the used encryption config type.
    @device.cmd('configure terminal')
    @device.cmd('feature tacacs+')
    @device.cmd("tacacs-server key #{encryption_type} TEST")
    @device.cmd('end')
    # Flush the cache since we've modified the device
    node.cache_flush
    tacacs = TacacsServer.new
    assert_equal(sh_run_encryption_password,
                 tacacs.encryption_password,
                 'Error: Tacacs Server, encryption password incorrect')
    tacacs.destroy
  end

  def test_tacacsserver_get_default_encryption_password
    assert_equal(node.config_get_default('tacacs_server', 'encryption_password'),
                 TacacsServer.default_encryption_password,
                 'Error: Tacacs Server, default encryption password incorrect')
  end

  def test_tacacsserver_key_set
    enc_type = TACACS_SERVER_ENC_NONE
    # This one is needed since the 'sh run' will always display the type
    # differently than the used encryption config type.
    sh_run_encryption_type = TACACS_SERVER_ENC_CISCO_TYPE_7
    password = 'TEST_NEW'

    tacacs = TacacsServer.new
    tacacs.encryption_key_set(enc_type, password)
    # Get the password from the running config since its encoded
    line = get_tacacsserver_match_line("key\s#{sh_run_encryption_type}\s\".*\"")
    refute_nil(line, 'Error: Tacacs Server, key not configured')
    # Extract encrypted password, and git rid of the "" around the pasword
    md = line.to_s
    encrypted_password = md.to_s.split(' ').last.tr('\"', '')
    # Extract encryption type
    md = /tacacs-server\skey\s\d/.match(line.to_s)
    encrypted_type = md.to_s.split(' ').last.to_i
    assert_equal(encrypted_type, tacacs.encryption_type,
                 'Error: Tacacs Server, encryption type incorrect')
    assert_equal(encrypted_password, tacacs.encryption_password,
                 'Error: Tacacs Server, encryption password incorrect')
    tacacs.destroy
  end

  def test_tacacsserver_key_unconfigure
    @device.cmd('conf t ; no feature tacacs+ ; end')
    node.cache_flush
    enc_type = TACACS_SERVER_ENC_NONE
    # This one is needed since the 'sh run' will always display the type
    # differently than the used encryption config type.
    sh_run_encryption_type = TACACS_SERVER_ENC_CISCO_TYPE_7
    password = 'TEST_NEW'

    tacacs = TacacsServer.new
    tacacs.encryption_key_set(enc_type, password)
    line = get_tacacsserver_match_line("key\s#{sh_run_encryption_type}\s\".*\"")
    refute_nil(line, 'Error: Tacacs Server, key not configured')

    enc_type = TACACS_SERVER_ENC_UNKNOWN
    password = ''
    tacacs.encryption_key_set(enc_type, password)
    line = get_tacacsserver_match_line("key\s#{sh_run_encryption_type}\s\".*\"")
    assert_nil(line, 'Error: Tacacs Server, key configured')
    tacacs.destroy
  end

  def test_tacacsserver_get_timeout
    tacacs = TacacsServer.new
    timeout = node.config_get_default('tacacs_server', 'timeout')
    assert_equal(timeout, tacacs.timeout,
                 'Error: Tacacs Server, timeout not default')

    timeout = 35
    @device.cmd('configure terminal')
    @device.cmd("tacacs-server timeout #{timeout}")
    @device.cmd('end')
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(timeout, tacacs.timeout,
                 'Error: Tacacs Server, timeout not configured')
    tacacs.destroy
  end

  def test_tacacsserver_get_default_timeout
    assert_equal(node.config_get_default('tacacs_server', 'timeout'),
                 TacacsServer.default_timeout,
                 'Error: Tacacs Server, default timeout incorrect')
  end

  def test_tacacsserver_set_timeout
    timeout = 45

    tacacs = TacacsServer.new
    tacacs.timeout = timeout
    line = get_tacacsserver_match_line("timeout\s.*")
    # Extract timeout
    md = /tacacs-server\stimeout\s\d*/.match(line.to_s)
    sh_run_timeout = md.to_s.split(' ').last.to_i
    # Need a better way to extract the timeout
    refute_nil(line, 'Error: Tacacs Server, timeout not configured')
    assert_equal(sh_run_timeout, tacacs.timeout,
                 'Error: Tacacs Server, timeout value incorrect')

    # Invalid case
    timeout = 80
    assert_raises(Cisco::CliError) do
      tacacs.timeout = timeout
    end
    tacacs.destroy
  end

  def test_tacacsserver_get_deadtime
    tacacs = TacacsServer.new
    deadtime = node.config_get_default('tacacs_server', 'deadtime')
    assert_equal(deadtime, tacacs.deadtime,
                 'Error: Tacacs Server, deadtime not default')

    deadtime = 850
    @device.cmd('configure terminal')
    @device.cmd("tacacs-server deadtime #{deadtime}")
    @device.cmd('end')
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(deadtime, tacacs.deadtime,
                 'Error: Tacacs Server, deadtime not configured')
    tacacs.destroy
  end

  def test_tacacsserver_get_default_deadtime
    assert_equal(node.config_get_default('tacacs_server', 'deadtime'),
                 TacacsServer.default_deadtime,
                 'Error: Tacacs Server, default deadtime incorrect')
  end

  def test_tacacsserver_set_deadtime
    deadtime = 1250

    tacacs = TacacsServer.new
    tacacs.deadtime = deadtime
    line = get_tacacsserver_match_line("deadtime\s.*")
    # Extract deadtime
    md = /tacacs-server\sdeadtime\s\d*/.match(line.to_s)
    sh_run_deadtime = md.to_s.split(' ').last.to_i
    refute_nil(line, 'Error: Tacacs Server, deadtime not configured')
    assert_equal(sh_run_deadtime, tacacs.deadtime,
                 'Error: Tacacs Server, deadtime incorrect')
    # Invalid case
    deadtime = 2450
    assert_raises(Cisco::CliError) do
      tacacs.deadtime = deadtime
    end
    tacacs.destroy
  end

  def test_tacacsserver_get_directed_request
    @device.cmd('conf t ; feature tacacs ; tacacs-server directed-request ; end')
    # Flush the cache since we've modified the device
    node.cache_flush
    tacacs = TacacsServer.new
    assert(tacacs.directed_request?,
           'Error: Tacacs Server, directed-request not set')

    @device.cmd('conf t ; no tacacs-server directed-request ; end')
    node.cache_flush
    refute(tacacs.directed_request?,
           'Error: Tacacs Server, directed-request set')
    tacacs.destroy
  end

  def test_tacacsserver_get_default_directed_request
    assert_equal(node.config_get_default('tacacs_server', 'directed_request'),
                 TacacsServer.default_directed_request,
                 'Error: Tacacs Server, default directed-request incorrect')
  end

  def test_tacacsserver_set_directed_request
    @device.cmd('conf t ; feature tacacs ; tacacs-server directed-request ; end')
    state = true
    tacacs = TacacsServer.new
    tacacs.directed_request = state
    line = get_tacacsserver_match_line('directed-request')
    refute_nil(line, 'Error: Tacacs Server, directed-request not configured')
    assert(tacacs.directed_request?,
           'Error: Tacacs Server, directed-request not set')

    # Turn it off
    @device.cmd('conf t ; no tacacs-server directed-request ; end')
    node.cache_flush
    refute(tacacs.directed_request?,
           'Error: Tacacs Server, directed-request set')

    # Turn it back on then go to default
    @device.cmd('conf t ; no tacacs-server directed-request ; end')
    state = node.config_get_default('tacacs_server', 'directed_request')
    tacacs.directed_request = state
    line = get_match_line('no tacacs-server directed-request')
    refute_nil(line,
               'Error: Tacacs Server, default directed-request not configured')

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

  def test_tacacsserver_get_source_interface
    @device.cmd('configure terminal')
    @device.cmd('no ip tacacs source-interface')
    @device.cmd('end')
    tacacs = TacacsServer.new
    intf = node.config_get_default('tacacs_server', 'source_interface')
    assert_equal(intf, tacacs.source_interface,
                 'Error: Tacacs Server, source-interface set')

    intf = 'Ethernet1/1'
    @device.cmd('configure terminal')
    @device.cmd("ip tacacs source-interface #{intf}")
    @device.cmd('end')
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(intf, tacacs.source_interface,
                 'Error: Tacacs Server, source-interface not correct')
    tacacs.destroy
  end

  def test_tacacsserver_get_default_source_interface
    assert_equal(node.config_get_default('tacacs_server', 'source_interface'),
                 TacacsServer.default_source_interface,
                 'Error: Tacacs Server, default source-interface incorrect')
  end

  def test_tacacsserver_set_source_interface
    @device.cmd('conf t ; feature tacacs+ ; no ip tacacs source-int ; end')
    node.cache_flush
    intf = node.config_get_default('tacacs_server', 'source_interface')
    tacacs = TacacsServer.new
    assert_equal(intf, tacacs.source_interface,
                 'Error: Tacacs Server, source-interface set')

    intf = 'Ethernet1/1'
    tacacs.source_interface = intf
    line = get_match_line("ip tacacs source-interface #{intf}")
    # Extract source-interface
    sh_run_source_interface = line.to_s.split(' ').last
    refute_nil(line, 'Error: Tacacs Server, source-interface not configured')
    assert_equal(sh_run_source_interface, tacacs.source_interface,
                 'Error: Tacacs Server, source-interface not correct')

    # Now bring it back to default
    intf = node.config_get_default('tacacs_server', 'source_interface')
    tacacs.source_interface = intf
    line = get_match_line('no ip tacacs source-interface')
    refute_nil(line, 'Error: Tacacs Server, source-interface not default')

    # Invalid case
    state = true
    assert_raises(TypeError) do
      tacacs.source_interface = state
    end
    tacacs.destroy
  end

  def test_tacacsserver_destroy
    tacacs = TacacsServer.new
    line = tacacsserver_feature
    refute_nil(line, 'Error: Tacacs feature not set')
    tacacs.destroy
    line = tacacsserver_feature
    assert_nil(line, 'Error: Tacacs feature still present')
  end
end
