# November 2014, Glenn F. Matthews
#
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

require_relative 'basetest'
require_relative '../lib/cisco_node_utils/node'

# TestNxapi - NXAPI client unit tests
class TestNxapi < TestCase
  @@client = nil # rubocop:disable Style/ClassVars

  def self.runnable_methods
    # If we're pointed to a gRPC node (as evidenced by presence of a port num)
    # then these tests don't apply
    return [:all_skipped] if Cisco::Environment.environment[:port]
    super
  end

  def all_skipped
    skip 'Node under test does not appear to use the NXAPI client'
  end

  def setup
    super
    @product_id = Cisco::Node.new.product_id if @product_id.nil?
    cleanup
  end

  def teardown
    cleanup
    super
  end

  def cleanup
    config_no_warn('no interface loopback41', 'no interface loopback42')
  end

  def client
    unless @@client
      client = Cisco::Client::NXAPI.new(Cisco::Environment.environment)
      client.cache_enable = true
      client.cache_auto = true
      @@client = client # rubocop:disable Style/ClassVars
    end
    @@client
  end

  # Test cases for new NXAPI client APIs

  def test_cli_set_string
    client.set(context: 'interface loopback41', values: 'descr panda')
    run = client.get(command: 'show run int loopback41')
    desc = run.match(/description (.*)/)[1]
    assert_equal(desc, 'panda')
  end

  def test_cli_set_array
    client.set(context: ['int loopback41'], values: ['descr elephant'])
    run = client.get(command: 'show run int loopback41')
    desc = run.match(/description (.*)/)[1]
    assert_equal(desc, 'elephant')
  end

  def test_cli_set_invalid
    input = ['int loopback41', 'exit', 'int loopback42', 'plover']
    successful = ['int loopback41', 'exit', 'int loopback42']
    rejected = 'plover'

    msg = case @product_id
          when /N(5|6|7)/
            'Input CLI command error'
          when /N(3|8|9)/
            'CLI execution error'
          end

    e = assert_raises Cisco::CliError do
      client.set(values: input)
    end

    cli_rcs = "
    cli return codes:
      successful : #{e.successful_input}
      rejected   : #{e.rejected_input}
      msg        : #{e.msg}
      code       : #{e.code}
      clierror   : #{e.clierror}
    "
    assert_equal(successful, e.successful_input, cli_rcs)
    assert_equal(rejected, e.rejected_input, cli_rcs)

    assert_match(msg, e.msg, cli_rcs)
    assert_equal('400', e.code, cli_rcs)
    assert_match('% Invalid command', e.clierror, cli_rcs)
  end

  def test_get_cli_default
    result = client.get(command: 'show hostname')
    s = @device.cmd('show hostname')
    assert_equal(result.strip, s.split("\n")[1].strip)
  end

  def test_get_cli_invalid
    assert_raises Cisco::CliError do
      client.get(command: 'show plugh')
    end
  end

  def test_element_get_cli_incomplete
    assert_raises Cisco::CliError do
      client.get(command: 'show ')
    end
  end

  def test_get_cli_explicit
    result = client.get(command: 'show hostname', data_format: :cli)
    s = @device.cmd('show hostname')
    assert_equal(result.strip, s.split("\n")[1].strip)
  end

  def test_get_cli_empty
    result = client.get(command:     'show hostname | incl foo | excl foo',
                        data_format: :cli)
    assert_nil(result)
  end

  def test_get_nxapi_structured
    result = client.get(command:     'show hostname',
                        data_format: :nxapi_structured)
    s = @device.cmd('show hostname')
    assert_equal(result['hostname'], s.split("\n")[1].strip)
  end

  def test_get_nxapi_structured_invalid
    assert_raises Cisco::CliError do
      client.get(command: 'show frobozz', data_format: :nxapi_structured)
    end
  end

  def test_get_nxapi_structured_unsupported
    cmd = { command:     'show snmp internal globals',
            data_format: :nxapi_structured }
    if @product_id[/N(5|6)/]
      assert_empty(client.get(cmd))
    else
      assert_raises(Cisco::RequestNotSupported) { client.get(cmd) }
    end
  end

  def test_connection_refused
    @device.cmd('configure terminal')
    @device.cmd('no feature nxapi')
    @device.cmd('end')
    assert_raises Cisco::ConnectionRefused do
      client.cache_flush
      client.get(command: 'show version')
    end
    assert_raises Cisco::ConnectionRefused do
      client.set(values: 'interface loopback41')
    end
    # On the off chance that things behave differently when NXAPI is
    # disabled while we're connected, versus trying to connect afresh...
    @@client = nil # rubocop:disable Style/ClassVars
    assert_raises Cisco::ConnectionRefused do
      client.get(command: 'show version')
    end
    assert_raises Cisco::ConnectionRefused do
      client.set(values: 'interface loopback41')
    end
  ensure
    @device.cmd('configure terminal')
    @device.cmd('feature nxapi')
    @device.cmd('end')
  end

  def test_unauthorized
    def client.password=(new) # rubocop:disable Style/TrivialAccessors
      @password = new
    end
    client.password = 'wrong_password'
    client.cache_flush
    assert_raises Cisco::AuthenticationFailed do
      client.get(command: 'show version')
    end
    assert_raises Cisco::AuthenticationFailed do
      client.set(values: 'interface loopback41')
    end
  ensure
    client.password = password
  end

  def test_unsupported
    # Add a method to the NXAPI that sends a request of invalid type
    def client.hello
      req('hello', 'world')
    end

    assert_raises Cisco::RequestNotSupported do
      client.hello
    end
  end

  def test_smart_create
    autoclient = Cisco::Client.create
    assert_equal(Cisco::Client::NXAPI, autoclient.class)
    assert(autoclient.supports?(:cli))
    assert(autoclient.supports?(:nxapi_structured))
    assert_equal(:nexus, autoclient.platform)
  end
end
