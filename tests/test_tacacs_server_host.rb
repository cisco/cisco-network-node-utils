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
require File.expand_path('../../lib/cisco_node_utils/tacacs_server_host', __FILE__)

include Cisco

DEFAULT_TACACS_SERVER_HOST_PORT = 49
DEFAULT_TACACS_SERVER_HOST_TIMEOUT = 0
DEFAULT_TACACS_SERVER_HOST_ENCRYPTION_PASSWORD = ''

# TestTacacsServerHost - Minitest for TacacsServerHost node utility
class TestTacacsServerHost < CiscoTestCase
  def get_tacacsserverhost_match_line(host_name)
    s = @device.cmd('show run all | no-more')
    cmd = 'tacacs-server host'
    pattern = /#{cmd}\s(#{host_name})(.*)/
    pattern.match(s)
  end

  def test_tacacsserverhost_collection_empty
    hosts = TacacsServerHost.hosts
    hosts.each_value(&:destroy)
    hosts = TacacsServerHost.hosts

    assert_empty(hosts, 'Error: Tacacs Host collection is not empty')
  end

  def test_tacacsserverhost_collection
    hosts_hash = {}
    hosts_hash['testhost1'] = 1138
    hosts_hash['testhost2'] = DEFAULT_TACACS_SERVER_HOST_PORT

    hosts_hash.each do |name, port|
      host = TacacsServerHost.new(name)
      host.port = port
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
    host = TacacsServerHost.new('testhost')
    line = get_tacacsserverhost_match_line('testhost')
    refute_nil(line, 'Error: Tacacs Host not created')
    host.destroy
  end

  def test_tacacsserverhost_destroy
    host_name = 'testhost'
    host = TacacsServerHost.new(host_name)
    line = get_tacacsserverhost_match_line(host_name)
    refute_nil(line, 'Error: Tacacs Host not created')
    host.destroy

    line = get_tacacsserverhost_match_line(host_name)
    assert_nil(line, 'Error: Tacacs Host still present')
  end

  def test_tacacsserverhost_get_name
    host_name = 'testhost'
    host = TacacsServerHost.new(host_name)
    line = get_tacacsserverhost_match_line(host_name)
    refute_nil(line, 'Error: Tacacs Host not found')
    assert_equal(host_name, line.captures[0],
                 "Error: #{host_name} name mismatch")
    assert_equal(host_name, host.name,
                 "Error: #{host_name} name get value mismatch")
    host.destroy
  end

  def test_tacacsserverhost_get_name_preconfigured
    host_name = 'testhost'

    @device.cmd('configure terminal')
    @device.cmd("tacacs-server host #{host_name}")
    @device.cmd('end')
    node.cache_flush

    line = get_tacacsserverhost_match_line(host_name)
    hosts = TacacsServerHost.hosts()

    refute_nil(line, 'Error: Tacacs Host not found')
    assert_equal(host_name, line.captures[0],
                 "Error: #{host_name} name mismatch")
    refute_nil(hosts[host_name], "Error: #{host_name} not retrieved.")
    assert_equal(host_name, hosts[host_name].name,
                 "Error: #{host_name} name get value mismatch")

    hosts.each_value(&:destroy)
  end

  def test_tacacsserverhost_get_name_formats
    host_name = 'testhost.example.com'
    host_ip = '192.168.1.1'

    @device.cmd('configure terminal')
    @device.cmd("tacacs-server host #{host_name}")
    @device.cmd("tacacs-server host #{host_ip}")
    @device.cmd('end')
    node.cache_flush

    line_name = get_tacacsserverhost_match_line(host_name)
    line_ip = get_tacacsserverhost_match_line(host_ip)
    hosts = TacacsServerHost.hosts

    refute_nil(line_name, 'Error: Tacacs Host not found')
    assert_equal(host_name, line_name.captures[0],
                 "Error: #{host_name} name mismatch")
    refute_nil(hosts[host_name], "Error: #{host_name} not retrieved.")
    assert_equal(host_name, hosts[host_name].name,
                 "Error: #{host_name} name get value mismatch")

    refute_nil(line_ip, 'Error: Tacacs Host not found')
    assert_equal(host_ip, line_ip.captures[0],
                 "Error: #{host_ip} name mismatch")
    refute_nil(hosts[host_ip], "Error: #{host_ip} not retrieved.")
    assert_equal(host_ip, hosts[host_ip].name,
                 "Error: #{host_ip} name get value mismatch")

    hosts.each_value(&:destroy)
  end

  def test_tacacsserverhost_get_port
    host_name = 'testhost'
    host = TacacsServerHost.new(host_name)

    # not previously configured
    port = DEFAULT_TACACS_SERVER_HOST_PORT
    assert_equal(port, host.port, 'Error: Tacacs Host port incorrect')

    # when configured
    port = 1138
    @device.cmd('configure terminal')
    @device.cmd("tacacs-server host #{host_name} port #{port}")
    @device.cmd('end')
    node.cache_flush
    assert_equal(port, host.port, 'Error: Tacacs Host port incorrect')

    host.destroy
  end

  def test_tacacsserverhost_get_default_port
    host = TacacsServerHost.new('testhost')

    port = DEFAULT_TACACS_SERVER_HOST_PORT
    assert_equal(port, TacacsServerHost.default_port,
                 'Error: Tacacs Host default port incorrect')
    host.destroy
  end

  def test_tacacsserverhost_set_port
    host_name = 'testhost'
    host = TacacsServerHost.new(host_name)

    port = 1138
    host.port = port
    line = get_tacacsserverhost_match_line(host_name)
    refute_nil(line, 'Error: Tacacs Host not found')
    md = /port\s(\d*)/.match(line.captures[1])
    refute_nil(md, 'Error: Tacacs Host port not found')
    assert_equal(port, md.captures[0].to_i, 'Error: Tacacs Host port mismatch')
    assert_equal(port, host.port, 'Error: Tacacs Host port incorrect')

    host.destroy
  end

  def test_tacacsserverhost_get_timeout
    # Cleanup first
    s = @device.cmd("show run | i 'tacacs.*timeout'")[/^tacacs.*timeout.*$/]
    if s
      @device.cmd("conf t ; no #{s} ; end")
      node.cache_flush
    end

    host_name = 'testhost'
    host = TacacsServerHost.new(host_name)

    # not previously configured
    timeout = DEFAULT_TACACS_SERVER_HOST_TIMEOUT
    assert_equal(timeout, host.timeout, 'Error: Tacacs Host timeout incorrect')

    # when configured
    timeout = 30
    @device.cmd('configure terminal')
    @device.cmd("tacacs-server host #{host_name} timeout #{timeout}")
    @device.cmd('end')
    node.cache_flush
    assert_equal(timeout, host.timeout, 'Error: Tacacs Host timeout incorrect')

    host.destroy
  end

  def test_tacacsserverhost_get_default_timeout
    host = TacacsServerHost.new('testhost')

    timeout = DEFAULT_TACACS_SERVER_HOST_TIMEOUT
    assert_equal(timeout, TacacsServerHost.default_timeout,
                 'Error: Tacacs Host default timeout incorrect')
    host.destroy
  end

  def test_tacacsserverhost_set_timeout
    host_name = 'testhost'
    host = TacacsServerHost.new(host_name)

    timeout = 30
    host.timeout = timeout
    line = get_tacacsserverhost_match_line(host_name)
    refute_nil(line, 'Error: Tacacs Host not found')
    md = /timeout\s(\d*)/.match(line.captures[1])
    refute_nil(md, 'Error: Tacacs Host timeout not found')
    assert_equal(timeout, md.captures[0].to_i,
                 'Error: Tacacs Host timeout mismatch')
    assert_equal(timeout, host.timeout, 'Error: Tacacs Host timeout incorrect')

    host.destroy
  end

  def test_tacacsserverhost_unset_timeout
    host_name = 'testhost'
    host = TacacsServerHost.new(host_name)

    timeout = DEFAULT_TACACS_SERVER_HOST_TIMEOUT
    host.timeout = timeout
    line = get_tacacsserverhost_match_line(host_name)
    refute_nil(line, 'Error: Tacacs Host not found')
    md = /timeout\s(\d*)/.match(line.captures[1])
    assert_nil(md, 'Error: Tacacs Host timeout found')
    assert_equal(timeout, host.timeout, 'Error: Tacacs Host timeout incorrect')

    host.destroy
  end

  def test_tacacsserverhost_get_encryption_type
    host_name = 'testhost'
    host = TacacsServerHost.new(host_name)

    # when not configured
    enctype = TACACS_SERVER_ENC_UNKNOWN

    assert_equal(enctype, host.encryption_type,
                 'Error: Tacacs Host encryption type incorrect')

    # when configured
    enctype = TACACS_SERVER_ENC_NONE
    sh_run_enctype = TACACS_SERVER_ENC_CISCO_TYPE_7
    @device.cmd('configure terminal')
    @device.cmd("tacacs-server host #{host_name} key #{enctype} TEST")
    @device.cmd('end')
    node.cache_flush
    assert_equal(sh_run_enctype, host.encryption_type,
                 'Error: Tacacs Host encryption type incorrect')
    host.destroy
  end

  def test_tacacsserverhost_get_default_encryption_type
    host = TacacsServerHost.new('testhost')

    assert_equal(TACACS_SERVER_ENC_NONE,
                 TacacsServerHost.default_encryption_type,
                 'Error: Tacacs Host default encryption type incorrect')
    host.destroy
  end

  def test_tacacsserverhost_get_encryption_password
    host_name = 'testhost'
    host = TacacsServerHost.new(host_name)

    # when not configured
    pass = DEFAULT_TACACS_SERVER_HOST_ENCRYPTION_PASSWORD
    assert_equal(pass, host.encryption_password,
                 'Error: Tacacs Host encryption password incorrect')

    # when configured
    pass = 'TEST'
    sh_run_pass = 'WAWY'
    @device.cmd('configure terminal')
    @device.cmd("tacacs-server host #{host_name} key 0 #{pass}")
    @device.cmd('end')
    node.cache_flush
    assert_equal(sh_run_pass, host.encryption_password,
                 'Error: Tacacs Host encryption password incorrect')
    host.destroy
  end

  def test_tacacsserverhost_get_default_encryption_password
    host = TacacsServerHost.new('testhost')

    assert_equal('', TacacsServerHost.default_encryption_password,
                 'Error: Tacacs Host default encryption password incorrect')
    host.destroy
  end

  def test_tacacsserverhost_set_key
    host_name = 'testhost'
    host = TacacsServerHost.new(host_name)

    enctype = TACACS_SERVER_ENC_NONE
    sh_run_enctype = TACACS_SERVER_ENC_CISCO_TYPE_7
    pass = 'TEST'
    sh_run_pass = 'WAWY'
    host.encryption_key_set(enctype, pass)

    line = get_tacacsserverhost_match_line(host_name)
    refute_nil(line, 'Error: Tacacs Host not found')
    md = /key\s(\d*)\s(\S*)/.match(line.captures[1])
    refute_nil(md, 'Error: Tacacs Host encryption not found')
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

    host.destroy
  end

  def test_tacacsserverhost_unset_key
    # Cleanup first
    s = @device.cmd("show run | i 'tacacs.*host'")[/^tacacs.*host.*$/]
    if s
      @device.cmd("conf t ; no #{s} ; end")
      node.cache_flush
    end

    host_name = 'testhost'
    host = TacacsServerHost.new(host_name)

    # First configure key value. Whether that can be passed
    # will be decided by test_tacacsserverhost_set_key
    enctype = TACACS_SERVER_ENC_NONE
    pass = 'TEST'
    host.encryption_key_set(enctype, pass)

    # Now unconfigure the key and verify
    enctype = TACACS_SERVER_ENC_UNKNOWN
    pass = DEFAULT_TACACS_SERVER_HOST_ENCRYPTION_PASSWORD
    host.encryption_key_set(enctype, pass)

    line = get_tacacsserverhost_match_line(host_name)
    refute_nil(line, 'Error: Tacacs Host not found')
    md = /key\s(\d*)\s(\S*)/.match(line.captures[1])
    assert_nil(md, 'Error: Tacacs Host encryption found')
    assert_equal(enctype, host.encryption_type,
                 'Error: Tacacs Host encryption type incorrect')
    assert_equal(pass, host.encryption_password,
                 'Error: Tacacs Host encryption password incorrect')
    host.destroy
  end
end
