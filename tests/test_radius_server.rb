#
# Minitest for RadiusServer class
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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/radius_server'

# TestRadiusServer - Minitest for RadiusServer node utility.
class TestRadiusSvr < CiscoTestCase
  @skip_unless_supported = 'radius_server'

  def setup
    # setup runs at the beginning of each test
    super
    no_radiusserver
  end

  def teardown
    # teardown runs at the end of each test
    no_radiusserver
    super
  end

  def setup_duplicates
    return if platform != :ios_xr
    config('radius-server host 8.8.8.8 auth-port 11 acct-port 44',
           'radius-server host 8.8.8.8 auth-port 22 acct-port 55',
           'radius-server host 8.8.8.8 auth-port 33 acct-port 66')
  end

  def no_duplicates
    return if platform != :ios_xr
    config('no radius-server host 8.8.8.8 auth-port 11 acct-port 44',
           'no radius-server host 8.8.8.8 auth-port 22 acct-port 55',
           'no radius-server host 8.8.8.8 auth-port 33 acct-port 66')
  end

  def no_radiusserver
    # Turn the feature off for a clean test.

    if platform == :ios_xr
      config('no radius-server host 8.8.8.8 auth-port 55 acct-port 44',
             'no radius-server host 2004::3 auth-port 55 acct-port 44',
             'no radius-server host 2005::7 auth-port 55 acct-port 44')
    else
      config('no radius-server host 8.8.8.8',
             'no radius-server host 2004::3',
             'no radius-server host 2005::7')
    end
  end

  # TESTS

  def test_create_destroy_single
    id = '8.8.8.8'
    refute_includes(Cisco::RadiusServer.radiusservers, id)

    server = Cisco::RadiusServer.new(id, true, 55, 44)

    assert_includes(Cisco::RadiusServer.radiusservers, id)
    assert_equal(server, Cisco::RadiusServer.radiusservers[id])

    assert_equal(44, Cisco::RadiusServer.radiusservers[id].acct_port)
    assert_equal(55, Cisco::RadiusServer.radiusservers[id].auth_port)

    if platform != :ios_xr
      # Default checking
      assert_equal(server.default_accounting, server.accounting)
      assert_equal(server.default_authentication, server.authentication)

      server.accounting = true
      assert(Cisco::RadiusServer.radiusservers[id].accounting)

      server.authentication = true
      assert(Cisco::RadiusServer.radiusservers[id].authentication)

      server.acct_port = 66
      assert_equal(66, Cisco::RadiusServer.radiusservers[id].acct_port)

      server.auth_port = 77
      assert_equal(77, Cisco::RadiusServer.radiusservers[id].auth_port)

      server.key_set(nil, nil)
      assert_equal(nil, Cisco::RadiusServer.radiusservers[id].key)

      key = '44444444'
      server.key_set(key, nil)
      assert_match(/#{key}/, Cisco::RadiusServer.radiusservers[id].key)
    else
      assert_nil(server.accounting)
      assert_raises(Cisco::UnsupportedError) do
        server.accounting = true
      end

      assert_nil(server.authentication)
      assert_raises(Cisco::UnsupportedError) do
        server.authentication = true
      end
    end

    server.retransmit_count = 3
    assert_equal(3, Cisco::RadiusServer.radiusservers[id].retransmit_count)

    if platform != :ios_xr
      # Setting back to default and re-checking
      server.acct_port = server.default_acct_port
      server.auth_port = server.default_auth_port
      server.accounting = server.default_accounting
      server.authentication = server.default_authentication
      assert_equal(server.default_acct_port, server.acct_port)
      assert_equal(server.default_auth_port, server.auth_port)
      assert_equal(server.default_accounting, server.accounting)
      assert_equal(server.default_authentication, server.authentication)
    end

    server.destroy
    refute_includes(Cisco::RadiusServer.radiusservers, id)
  end

  def test_create_destroy_single_with_duplicates
    setup_duplicates

    id = '8.8.8.8'

    server = Cisco::RadiusServer.new(id, true, 55, 44)

    assert_includes(Cisco::RadiusServer.radiusservers, id)
    assert_equal(server, Cisco::RadiusServer.radiusservers[id])

    assert_equal(44, Cisco::RadiusServer.radiusservers[id].acct_port)
    assert_equal(55, Cisco::RadiusServer.radiusservers[id].auth_port)

    if platform != :ios_xr
      # Default checking
      assert_equal(server.default_accounting, server.accounting)
      assert_equal(server.default_authentication, server.authentication)

      server.accounting = true
      assert(Cisco::RadiusServer.radiusservers[id].accounting)

      server.authentication = true
      assert(Cisco::RadiusServer.radiusservers[id].authentication)

      server.acct_port = 66
      assert_equal(66, Cisco::RadiusServer.radiusservers[id].acct_port)

      server.auth_port = 77
      assert_equal(77, Cisco::RadiusServer.radiusservers[id].auth_port)

      key = '44444444'
      server.key_set(key, nil)
      assert_match(/#{key}/, Cisco::RadiusServer.radiusservers[id].key)
    else
      assert_nil(server.accounting)
      assert_raises(Cisco::UnsupportedError) do
        server.accounting = true
      end

      assert_nil(server.authentication)
      assert_raises(Cisco::UnsupportedError) do
        server.authentication = true
      end
    end

    server.retransmit_count = 3
    assert_equal(3, Cisco::RadiusServer.radiusservers[id].retransmit_count)

    if platform != :ios_xr
      # Setting back to default and re-checking
      server.acct_port = server.default_acct_port
      server.auth_port = server.default_auth_port
      server.accounting = server.default_accounting
      server.authentication = server.default_authentication
      assert_equal(server.default_acct_port, server.acct_port)
      assert_equal(server.default_auth_port, server.auth_port)
      assert_equal(server.default_accounting, server.accounting)
      assert_equal(server.default_authentication, server.authentication)
    end

    server.destroy
    refute_includes(Cisco::RadiusServer.radiusservers, id)

    no_duplicates
  end

  def test_create_destroy_single_ipv6
    id = '2004::3'
    refute_includes(Cisco::RadiusServer.radiusservers, id)

    server = Cisco::RadiusServer.new(id, true, 55, 44)

    assert_includes(Cisco::RadiusServer.radiusservers, id)
    assert_equal(server, Cisco::RadiusServer.radiusservers[id])

    assert_equal(44, Cisco::RadiusServer.radiusservers[id].acct_port)
    assert_equal(55, Cisco::RadiusServer.radiusservers[id].auth_port)

    if platform != :ios_xr
      # Default checking
      assert_equal(server.default_accounting, server.accounting)
      assert_equal(server.default_authentication, server.authentication)

      server.accounting = true
      assert(Cisco::RadiusServer.radiusservers[id].accounting)

      server.authentication = true
      assert(Cisco::RadiusServer.radiusservers[id].authentication)

      server.acct_port = 66
      assert_equal(66, Cisco::RadiusServer.radiusservers[id].acct_port)

      server.auth_port = 77
      assert_equal(77, Cisco::RadiusServer.radiusservers[id].auth_port)

      key = '44444444'
      server.key_set(key, nil)
      assert_match(/#{key}/, Cisco::RadiusServer.radiusservers[id].key)
    else
      assert_nil(server.accounting)
      assert_raises(Cisco::UnsupportedError) do
        server.accounting = true
      end

      assert_nil(server.authentication)
      assert_raises(Cisco::UnsupportedError) do
        server.authentication = true
      end
    end

    server.retransmit_count = 3
    assert_equal(3, Cisco::RadiusServer.radiusservers[id].retransmit_count)

    if platform != :ios_xr
      # Setting back to default and re-checking
      server.acct_port = server.default_acct_port
      server.auth_port = server.default_auth_port
      server.accounting = server.default_accounting
      server.authentication = server.default_authentication
      assert_equal(server.default_acct_port, server.acct_port)
      assert_equal(server.default_auth_port, server.auth_port)
      assert_equal(server.default_accounting, server.accounting)
      assert_equal(server.default_authentication, server.authentication)
    end

    server.destroy
    refute_includes(Cisco::RadiusServer.radiusservers, id)
  end

  def test_radiusserver_create_destroy_multiple
    id = '8.8.8.8'
    id2 = '2005::7'

    refute_includes(Cisco::RadiusServer.radiusservers, id)
    refute_includes(Cisco::RadiusServer.radiusservers, id2)

    server = Cisco::RadiusServer.new(id, true, 55, 44)
    server2 = Cisco::RadiusServer.new(id2, true, 55, 44)

    assert_includes(Cisco::RadiusServer.radiusservers, id)
    assert_equal(server, Cisco::RadiusServer.radiusservers[id])
    assert_includes(Cisco::RadiusServer.radiusservers, id2)
    assert_equal(server2, Cisco::RadiusServer.radiusservers[id2])

    assert_equal(44, Cisco::RadiusServer.radiusservers[id].acct_port)
    assert_equal(55, Cisco::RadiusServer.radiusservers[id].auth_port)

    if platform != :ios_xr
      # Default checking
      assert_equal(server.default_accounting, server.accounting)
      assert_equal(server.default_authentication, server.authentication)
      assert_equal(server2.default_accounting, server2.accounting)
      assert_equal(server2.default_authentication, server2.authentication)

      server.accounting = true
      assert(Cisco::RadiusServer.radiusservers[id].accounting)

      server.authentication = true
      assert(Cisco::RadiusServer.radiusservers[id].authentication)

      server.acct_port = 66
      assert_equal(66, Cisco::RadiusServer.radiusservers[id].acct_port)

      server.auth_port = 77
      assert_equal(77, Cisco::RadiusServer.radiusservers[id].auth_port)

      key = '44444444'
      server.key_set(key, nil)
      assert_match(/#{key}/, Cisco::RadiusServer.radiusservers[id].key)
      assert_match(/#{key}/, server.key)
    else
      assert_nil(server.accounting)
      assert_raises(Cisco::UnsupportedError) do
        server.accounting = true
      end

      assert_nil(server.authentication)
      assert_raises(Cisco::UnsupportedError) do
        server.authentication = true
      end
    end

    server.retransmit_count = 3
    assert_equal(3, Cisco::RadiusServer.radiusservers[id].retransmit_count)

    assert_equal(44, Cisco::RadiusServer.radiusservers[id2].acct_port)
    assert_equal(55, Cisco::RadiusServer.radiusservers[id2].auth_port)

    if platform != :ios_xr
      server2.accounting = true
      assert(Cisco::RadiusServer.radiusservers[id2].accounting)

      server2.authentication = true
      assert(Cisco::RadiusServer.radiusservers[id2].authentication)

      server2.acct_port = 66
      assert_equal(66, Cisco::RadiusServer.radiusservers[id2].acct_port)

      server2.auth_port = 77
      assert_equal(77, Cisco::RadiusServer.radiusservers[id2].auth_port)

      key = '44444444'
      server2.key_set(key, nil)
      assert_match(/#{key}/, Cisco::RadiusServer.radiusservers[id2].key)
    else
      assert_nil(server.accounting)
      assert_raises(Cisco::UnsupportedError) do
        server2.accounting = true
      end

      assert_nil(server.authentication)
      assert_raises(Cisco::UnsupportedError) do
        server2.authentication = true
      end
    end

    server2.retransmit_count = 3
    assert_equal(3, Cisco::RadiusServer.radiusservers[id2].retransmit_count)

    if platform != :ios_xr
      # Setting back to default and re-checking
      server.acct_port = server.default_acct_port
      server.auth_port = server.default_auth_port
      server.accounting = server.default_accounting
      server.authentication = server.default_authentication
      server2.acct_port = server2.default_acct_port
      server2.auth_port = server2.default_auth_port
      server2.accounting = server2.default_accounting
      server2.authentication = server2.default_authentication
      assert_equal(server.default_acct_port, server.acct_port)
      assert_equal(server.default_auth_port, server.auth_port)
      assert_equal(server.default_accounting, server.accounting)
      assert_equal(server.default_authentication, server.authentication)
      assert_equal(server2.default_acct_port, server2.acct_port)
      assert_equal(server2.default_auth_port, server2.auth_port)
      assert_equal(server2.default_accounting, server2.accounting)
      assert_equal(server2.default_authentication, server2.authentication)
    end

    server.destroy
    server2.destroy
    refute_includes(Cisco::RadiusServer.radiusservers, id)
    refute_includes(Cisco::RadiusServer.radiusservers, id2)
  end
end
