#
# Minitest for TacacsServerHost class
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
require_relative '../lib/cisco_node_utils/tacacs_server_host'

# TestTacacsServerHost - Minitest for TacacsServerHost node utility.
class TestTacacsServerHost < CiscoTestCase
  @skip_unless_supported = 'tacacs_server_host'

  def setup
    # setup runs at the beginning of each test
    super
    no_tacacsserver
  end

  def teardown
    # teardown runs at the end of each test
    no_tacacsserver
    super
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

  def no_tacacsserver
    # Turn the feature off for a clean test.

    if platform == :ios_xr
      config('no tacacs-server host 8.8.8.8 port 55',
             'no tacacs-server host 2004::3 port 55',
             'no tacacs-server host 2005::7 port 55')
    else
      config('no tacacs-server host 8.8.8.8',
             'no tacacs-server host 2004::3',
             'no tacacs-server host 2005::7')
    end
  end

  # TESTS

  def test_create_destroy_single
    id = '8.8.8.8'
    refute_includes(Cisco::TacacsServerHost.hosts, id)

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
  end

  def test_create_destroy_single_with_duplicates
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

  def test_create_destroy_single_ipv6
    id = '2004::3'

    refute_includes(Cisco::TacacsServerHost.hosts, id)

    server = Cisco::TacacsServerHost.new(id, true, 55)

    assert_includes(Cisco::TacacsServerHost.hosts, id)
    assert_equal(server, Cisco::TacacsServerHost.hosts[id])

    assert_equal(55, Cisco::TacacsServerHost.hosts[id].port)

    if platform != :ios_xr
      server.port = 66
      assert_equal(66, Cisco::TacacsServerHost.hosts[id].port)

      server.encryption_key_set(nil, nil)
      assert_equal(nil, Cisco::TacacsServerHost.hosts[id].encryption_password)

      server.encryption_key_set('44444444', nil)
      assert_equal('44444444',
                   Cisco::TacacsServerHost.hosts[id].encryption_password)
    end

    server.timeout = 33
    assert_equal(33, Cisco::TacacsServerHost.hosts[id].timeout)

    server.destroy
    refute_includes(Cisco::TacacsServerHost.hosts, id)
  end

  def test_create_destroy_multiple
    id = '8.8.8.8'
    id2 = '2005::7'

    refute_includes(Cisco::TacacsServerHost.hosts, id)
    refute_includes(Cisco::TacacsServerHost.hosts, id2)

    server = Cisco::TacacsServerHost.new(id, true, 55)

    assert_includes(Cisco::TacacsServerHost.hosts, id)
    assert_equal(server, Cisco::TacacsServerHost.hosts[id])

    assert_equal(55, Cisco::TacacsServerHost.hosts[id].port)

    if platform != :ios_xr
      server.port = 66
      assert_equal(66, Cisco::TacacsServerHost.hosts[id].port)

      server.encryption_key_set(nil, nil)
      assert_equal(nil, Cisco::TacacsServerHost.hosts[id].encryption_password)

      server.encryption_key_set('44444444', nil)
      assert_equal('44444444',
                   Cisco::TacacsServerHost.hosts[id].encryption_password)
    end

    server.timeout = 33
    assert_equal(33, Cisco::TacacsServerHost.hosts[id].timeout)

    server2 = Cisco::TacacsServerHost.new(id2, true, 55)

    assert_includes(Cisco::TacacsServerHost.hosts, id2)
    assert_equal(server2, Cisco::TacacsServerHost.hosts[id2])

    assert_equal(55, Cisco::TacacsServerHost.hosts[id2].port)

    if platform != :ios_xr
      server2.port = 66
      assert_equal(66, Cisco::TacacsServerHost.hosts[id2].port)

      server2.encryption_key_set(nil, nil)
      assert_equal(nil, Cisco::TacacsServerHost.hosts[id2].encryption_password)

      server2.encryption_key_set('44444444', nil)
      assert_equal('44444444',
                   Cisco::TacacsServerHost.hosts[id2].encryption_password)
    end

    server2.timeout = 33
    assert_equal(33, Cisco::TacacsServerHost.hosts[id2].timeout)

    server.destroy
    server2.destroy
    refute_includes(Cisco::TacacsServerHost.hosts, id)
    refute_includes(Cisco::TacacsServerHost.hosts, id2)
  end
end
