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
require_relative '../lib/cisco_node_utils/tacacs_server_host'

include Cisco

DEFAULT_TACACS_SERVER_HOST_PORT = 49
DEFAULT_TACACS_SERVER_HOST_TIMEOUT = 0
DEFAULT_TACACS_SERVER_HOST_ENCRYPTION_PASSWORD = ''

# TestTacacsServerHost - Minitest for TacacsServerHost node utility
class TestTacacsServerHost < CiscoTestCase
  @skip_unless_supported = 'tacacs_server_host'

  def setup
    super
    if platform == :nexus
      @host_name = 'testhost'
      @default_show_command = 'show run all | inc "tacacs-server" | no-more'
    else
      @default_show_command = 'show running-config tacacs-server'
      @host_name = '2.2.2.2'
    end
    @default_output_pattern = /tacacs-server host\s(#{@host_name})(.*)/
  end

  # Not for Nexus
  def no_tacacsserver
    # Turn the feature off for a clean test.
    config('no aaa group server tacacs red',
           'no aaa group server tacacs blue')
  end

  def test_tacacsserverhost_collection_empty
    hosts = TacacsServerHost.hosts
    hosts.each_value(&:destroy)
    hosts = TacacsServerHost.hosts

    assert_empty(hosts, 'Error: Tacacs Host collection is not empty')
  end

  def test_tacacsserverhost_collection
    hosts_hash = {}
    hosts_hash['4.4.4.4'] = 1138
    hosts_hash['5.5.5.5'] = DEFAULT_TACACS_SERVER_HOST_PORT

    hosts_hash.each do |name, port|
      if platform != :ios_xr
        host = TacacsServerHost.new(name)
        host.port = port
      else
        TacacsServerHost.new(name, true, port)
      end
    end

    hosts = TacacsServerHost.hosts
    refute_empty(hosts, 'Error: Tacacs Host collection is empty')
    hosts_hash.each do |name, port|
      # host must have been created to be found in the list
      assert(hosts.include?(name),
             "Error: Tacacs Host #{name} not in collection")
      # port numbers differentiate the hosts
      assert_equal(port, hosts[name].port,
                   "Error: Tacacs Host #{name} port mismatch")
    end

    hosts_hash.each_key { |name| hosts[name].destroy }
  end

  def test_tacacsserverhost_create_server_nil
    assert_raises(TypeError) { TacacsServerHost.new(nil) }
  end

  def test_tacacsserverhost_create_name_zero_length
    assert_raises(ArgumentError) { TacacsServerHost.new('') }
  end

  def test_tacacsserverhost_create_valid
    host = TacacsServerHost.new(@host_name)
    assert_show_match(msg: 'Error: Tacacs Host not created')
    host.destroy
  end

  def test_tacacsserverhost_destroy
    host = TacacsServerHost.new(@host_name)
    assert_show_match(msg: 'Error: Tacacs Host not created')
    host.destroy

    refute_show_match(msg: 'Error: Tacacs Host still present')
  end

  def test_tacacsserverhost_get_name
    host = TacacsServerHost.new(@host_name)
    line = assert_show_match(msg: 'Error: Tacacs Host not found')
    assert_equal(@host_name, line.captures[0],
                 "Error: #{@host_name} name mismatch")
    assert_equal(@host_name, host.name,
                 "Error: #{@host_name} name get value mismatch")
    host.destroy
  end

  def test_tacacsserverhost_get_name_preconfigured
    config("tacacs-server host #{@host_name}")

    line = assert_show_match(msg: 'Error: Tacacs Host not found')
    hosts = TacacsServerHost.hosts()

    assert_equal(@host_name, line.captures[0],
                 "Error: #{@host_name} name mismatch")
    refute_nil(hosts[@host_name], "Error: #{@host_name} not retrieved.")
    assert_equal(@host_name, hosts[@host_name].name,
                 "Error: #{@host_name} name get value mismatch")

    hosts.each_value(&:destroy)
  end

  def test_tacacsserverhost_get_name_formats
    host_name = 'testhost.example.com'
    host_ip = '192.168.1.1'

    config("tacacs-server host #{host_name}") unless platform == :ios_xr
    config("tacacs-server host #{host_ip}")

    line_name = assert_show_match(
      pattern: /tacacs-server host\s(testhost\.example\.com)(.*)/,
      msg:     'Error: Tacacs Host not found') unless platform == :ios_xr
    line_ip = assert_show_match(
      pattern: /tacacs-server host\s(192\.168\.1\.1)(.*)/,
      msg:     'Error: Tacacs Host not found')
    hosts = TacacsServerHost.hosts

    unless platform == :ios_xr
      assert_equal(host_name, line_name.captures[0],
                   "Error: #{host_name} name mismatch")
      refute_nil(hosts[host_name], "Error: #{host_name} not retrieved.")
      assert_equal(host_name, hosts[host_name].name,
                   "Error: #{host_name} name get value mismatch")
    end

    assert_equal(host_ip, line_ip.captures[0],
                 "Error: #{host_ip} name mismatch")
    refute_nil(hosts[host_ip], "Error: #{host_ip} not retrieved.")
    assert_equal(host_ip, hosts[host_ip].name,
                 "Error: #{host_ip} name get value mismatch")

    hosts.each_value(&:destroy)
  end

  def test_tacacsserverhost_get_port
    host = TacacsServerHost.new(@host_name)

    # not previously configured
    port = DEFAULT_TACACS_SERVER_HOST_PORT
    assert_equal(port, host.port, 'Error: Tacacs Host port incorrect')

    # IOS XR support the same host using different ports
    unless platform == :ios_xr
      # when configured
      port = 1138
      host.port = port
      assert_equal(port, host.port, 'Error: Tacacs Host port incorrect')
    end

    host.destroy
  end

  def test_tacacsserverhost_get_default_port
    host = TacacsServerHost.new(@host_name)

    port = DEFAULT_TACACS_SERVER_HOST_PORT
    assert_equal(port, TacacsServerHost.default_port,
                 'Error: Tacacs Host default port incorrect')
    host.destroy
  end

  def test_tacacsserverhost_set_port
    return if platform == :ios_xr

    host = TacacsServerHost.new(@host_name)

    port = 1138
    host.port = port
    line = assert_show_match(msg: 'Error: Tacacs Host not found')
    assert_match(/port\s(\d*)/, line.captures[1])
    md = /port\s(\d*)/.match(line.captures[1])
    assert_equal(port, md.captures[0].to_i, 'Error: Tacacs Host port mismatch')
    assert_equal(port, host.port, 'Error: Tacacs Host port incorrect')

    host.destroy
  end

  def test_tacacsserverhost_get_timeout
    # Cleanup first
    s = @device.cmd("show run | i 'tacacs.*timeout'")[/^tacacs.*timeout.*$/]
    config("no #{s}") if s

    host = TacacsServerHost.new(@host_name)

    # not previously configured
    timeout = DEFAULT_TACACS_SERVER_HOST_TIMEOUT
    assert_equal(timeout, host.timeout, 'Error: Tacacs Host timeout incorrect')

    # when configured
    timeout = 30
    host.timeout = timeout
    assert_equal(timeout, host.timeout, 'Error: Tacacs Host timeout incorrect')

    host.destroy
  end

  def test_tacacsserverhost_get_default_timeout
    host = TacacsServerHost.new(@host_name)

    timeout = DEFAULT_TACACS_SERVER_HOST_TIMEOUT
    assert_equal(timeout, TacacsServerHost.default_timeout,
                 'Error: Tacacs Host default timeout incorrect')
    host.destroy
  end

  def test_tacacsserverhost_set_timeout
    host = TacacsServerHost.new(@host_name)

    timeout = 30
    host.timeout = timeout
    line = assert_show_match(msg: 'Error: Tacacs Host not found')

    if platform != :ios_xr
      assert_match(/timeout\s(\d*)/, line.captures[1])
      md = /timeout\s(\d*)/.match(line.captures[1])
      assert_equal(timeout, md.captures[0].to_i,
                   'Error: Tacacs Host timeout mismatch')
    end

    assert_equal(timeout, host.timeout, 'Error: Tacacs Host timeout incorrect')

    host.destroy
  end

  def test_tacacsserverhost_unset_timeout
    host = TacacsServerHost.new(@host_name)

    timeout = DEFAULT_TACACS_SERVER_HOST_TIMEOUT
    host.timeout = timeout
    line = assert_show_match(msg: 'Error: Tacacs Host not found')
    refute_match(/timeout\s(\d*)/, line.captures[1])
    assert_equal(timeout, host.timeout, 'Error: Tacacs Host timeout incorrect')

    host.destroy
  end

  def test_tacacsserverhost_get_encryption_type
    host = TacacsServerHost.new(@host_name)

    # when not configured
    enctype = TACACS_SERVER_ENC_UNKNOWN

    assert_equal(enctype, host.encryption_type,
                 'Error: Tacacs Host encryption type incorrect')

    # when configured
    enctype = TACACS_SERVER_ENC_NONE
    sh_run_enctype = TACACS_SERVER_ENC_CISCO_TYPE_7
    host.encryption_key_set(enctype, 'TEST')
    assert_equal(sh_run_enctype, host.encryption_type,
                 'Error: Tacacs Host encryption type incorrect')
    host.destroy
  end

  def test_tacacsserverhost_get_default_encryption_type
    host = TacacsServerHost.new(@host_name)

    assert_equal(TACACS_SERVER_ENC_NONE,
                 TacacsServerHost.default_encryption_type,
                 'Error: Tacacs Host default encryption type incorrect')
    host.destroy
  end

  def test_tacacsserverhost_get_encryption_password
    host = TacacsServerHost.new(@host_name)

    # when not configured
    pass = DEFAULT_TACACS_SERVER_HOST_ENCRYPTION_PASSWORD
    assert_equal(pass, host.encryption_password,
                 'Error: Tacacs Host encryption password incorrect')

    # when configured
    pass = 'TEST'
    sh_run_pass = 'WAWY'
    host.encryption_key_set(0, pass)

    if platform != :ios_xr
      assert_equal(sh_run_pass, host.encryption_password,
                   'Error: Tacacs Host encryption password incorrect')
    else
      # Only do not-nil checking for IOS XR
      assert(!host.encryption_password.nil?)
    end

    host.destroy
  end

  def test_tacacsserverhost_get_default_encryption_password
    host = TacacsServerHost.new(@host_name)

    assert_equal('', TacacsServerHost.default_encryption_password,
                 'Error: Tacacs Host default encryption password incorrect')
    host.destroy
  end

  def test_tacacsserverhost_set_key
    host = TacacsServerHost.new(@host_name)

    enctype = TACACS_SERVER_ENC_NONE
    sh_run_enctype = TACACS_SERVER_ENC_CISCO_TYPE_7
    pass = 'TEST'
    sh_run_pass = 'WAWY'
    host.encryption_key_set(enctype, pass)

    line = assert_show_match(msg: 'Error: Tacacs Host not found')

    if platform != :ios_xr
      assert_match(/key\s(\d*)\s(\S*)/, line.captures[1])
      md = /key\s(\d*)\s(\S*)/.match(line.captures[1])
      assert_equal(sh_run_enctype, md.captures[0].to_i,
                   'Error: Tacacs Host encryption type mismatch')
      assert_equal(sh_run_enctype, host.encryption_type,
                   'Error: Tacacs Host encryption type incorrect')
      # remove quotes surrounding the encrypted password
      pass_no_quotes = md.captures[1].gsub(/(?:^\")|(?:\"$)/, '')
      assert_equal(sh_run_pass, pass_no_quotes,
                   'Error: Tacacs Host encryption password mismatch')
      assert_equal(sh_run_pass, host.encryption_password,
                   'Error: Tacacs Host encryption password incorrect')
    else
      # Only do not-nil checking for IOS XR
      assert(!host.encryption_password.nil?)
    end

    host.destroy
  end

  def test_tacacsserverhost_unset_key
    # Cleanup first
    s = @device.cmd("show run | i 'tacacs.*host'")[/^tacacs.*host.*$/]
    config("no #{s}") if s

    host = TacacsServerHost.new(@host_name)

    # First configure key value. Whether that can be passed
    # will be decided by test_tacacsserverhost_set_key
    enctype = TACACS_SERVER_ENC_NONE
    pass = 'TEST'
    host.encryption_key_set(enctype, pass)

    # Now unconfigure the key and verify
    enctype = TACACS_SERVER_ENC_UNKNOWN
    pass = DEFAULT_TACACS_SERVER_HOST_ENCRYPTION_PASSWORD
    host.encryption_key_set(enctype, pass)

    line = assert_show_match(msg: 'Error: Tacacs Host not found')
    refute_match(/key\s(\d*)\s(\S*)/, line.captures[1])
    assert_equal(enctype, host.encryption_type,
                 'Error: Tacacs Host encryption type incorrect')
    assert_equal(pass, host.encryption_password,
                 'Error: Tacacs Host encryption password incorrect')
    host.destroy
  end

  def setup_duplicates
    return if platform != :ios_xr
    config('tacacs-server host 8.8.8.8 port 11',
           'tacacs-server host 8.8.8.8 port 22',
           'tacacs-server host 8.8.8.8 port 33')
  end

  def no_duplicates
    return if platform != :ios_xr
    config('no tacacs-server host 8.8.8.8 port 11',
           'no tacacs-server host 8.8.8.8 port 22',
           'no tacacs-server host 8.8.8.8 port 33')
  end

  def test_create_destroy_single_with_duplicates
    return if platform != :ios_xr
    setup_duplicates

    id = '8.8.8.8'

    server = Cisco::TacacsServerHost.new(id, true, 55)

    assert_includes(Cisco::TacacsServerHost.hosts, id)
    assert_equal(server, Cisco::TacacsServerHost.hosts[id])

    assert_equal(55, Cisco::TacacsServerHost.hosts[id].port)

    if platform != :ios_xr
      server.port = 66
      assert_equal(66, Cisco::TacacsServerHost.hosts[id].port)

      server.encryption_key_set(nil, nil)
      assert_equal(nil,
                   Cisco::TacacsServerHost.hosts[id].encryption_password)

      server.encryption_key_set('44444444', nil)
      assert_equal('44444444',
                   Cisco::TacacsServerHost.hosts[id].encryption_password)
    end

    server.timeout = 33
    assert_equal(33, Cisco::TacacsServerHost.hosts[id].timeout)

    server.destroy
    refute_includes(Cisco::TacacsServerHost.hosts, id)

    no_duplicates
  end
end
