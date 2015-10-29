#
# Minitest for RadiusServer class
#
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
require File.expand_path('../../lib/cisco_node_utils/radius_server', __FILE__)

# TestRadiusServer - Minitest for RadiusServer node utility.
class TestRadiusServer < CiscoTestCase
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

  def no_radiusserver
    # Turn the feature off for a clean test.
    config('no radius-server host 8.8.8.8',
           'no radius-server host 9.9.9.9')
  end

  # TESTS

  def test_radiusserver_create_destroy_single
    id = '8.8.8.8'
    refute_includes(Cisco::RadiusServer.radiusservers, id)

    server = Cisco::RadiusServer.new(id, true)
    assert_includes(Cisco::RadiusServer.radiusservers, id)
    assert_equal(Cisco::RadiusServer.radiusservers[id], server)

    # Default checking
    assert_equal(server.acct_port, server.default_acct_port)
    assert_equal(server.auth_port, server.default_auth_port)
    assert_equal(server.accounting, server.default_accounting)
    assert_equal(server.authentication, server.default_authentication)

    server.accounting = true
    assert(Cisco::RadiusServer.radiusservers[id].accounting)

    server.authentication = true
    assert(Cisco::RadiusServer.radiusservers[id].authentication)

    server.acct_port = 44
    assert_equal(Cisco::RadiusServer.radiusservers[id].acct_port,
                 44)

    server.auth_port = 55
    assert_equal(Cisco::RadiusServer.radiusservers[id].auth_port,
                 55)

    server.retransmit_count = 3
    assert_equal(Cisco::RadiusServer.radiusservers[id].retransmit_count,
                 3)

    server.key_set('44444444', nil)
    assert_equal(Cisco::RadiusServer.radiusservers[id].key,
                 '44444444')

    # Setting back to default and re-checking
    server.acct_port = server.default_acct_port
    server.auth_port = server.default_auth_port
    server.accounting = server.default_accounting
    server.authentication = server.default_authentication
    assert_equal(server.acct_port, server.default_acct_port)
    assert_equal(server.auth_port, server.default_auth_port)
    assert_equal(server.accounting, server.default_accounting)
    assert_equal(server.authentication, server.default_authentication)

    server.destroy
    refute_includes(Cisco::RadiusServer.radiusservers, id)
  end

  def test_radiusserver_create_destroy_multiple
    id = '8.8.8.8'
    id2 = '9.9.9.9'
    refute_includes(Cisco::RadiusServer.radiusservers, id)
    refute_includes(Cisco::RadiusServer.radiusservers, id2)

    server = Cisco::RadiusServer.new(id, true)
    server2 = Cisco::RadiusServer.new(id2, true)
    assert_includes(Cisco::RadiusServer.radiusservers, id)
    assert_equal(Cisco::RadiusServer.radiusservers[id], server)
    assert_includes(Cisco::RadiusServer.radiusservers, id2)
    assert_equal(Cisco::RadiusServer.radiusservers[id2], server2)

    # Default checking
    assert_equal(server.acct_port, server.default_acct_port)
    assert_equal(server.auth_port, server.default_auth_port)
    assert_equal(server.accounting, server.default_accounting)
    assert_equal(server.authentication, server.default_authentication)
    assert_equal(server2.acct_port, server2.default_acct_port)
    assert_equal(server2.auth_port, server2.default_auth_port)
    assert_equal(server2.accounting, server2.default_accounting)
    assert_equal(server2.authentication, server2.default_authentication)

    server.accounting = true
    assert(Cisco::RadiusServer.radiusservers[id].accounting)

    server.authentication = true
    assert(Cisco::RadiusServer.radiusservers[id].authentication)

    server.acct_port = 44
    assert_equal(Cisco::RadiusServer.radiusservers[id].acct_port,
                 44)

    server.auth_port = 55
    assert_equal(Cisco::RadiusServer.radiusservers[id].auth_port,
                 55)

    server.retransmit_count = 3
    assert_equal(Cisco::RadiusServer.radiusservers[id].retransmit_count,
                 3)

    server.key_set('44444444', nil)
    assert_equal(Cisco::RadiusServer.radiusservers[id].key,
                 '44444444')
    assert_equal(server.key,
                 '44444444')

    server2.accounting = true
    assert(Cisco::RadiusServer.radiusservers[id2].accounting)

    server2.authentication = true
    assert(Cisco::RadiusServer.radiusservers[id2].authentication)

    server2.acct_port = 44
    assert_equal(Cisco::RadiusServer.radiusservers[id2].acct_port,
                 44)

    server2.auth_port = 55
    assert_equal(Cisco::RadiusServer.radiusservers[id2].auth_port,
                 55)

    server2.retransmit_count = 3
    assert_equal(Cisco::RadiusServer.radiusservers[id2].retransmit_count,
                 3)

    server2.key_set('44444444', nil)
    assert_equal(Cisco::RadiusServer.radiusservers[id2].key,
                 '44444444')

    # Setting back to default and re-checking
    server.acct_port = server.default_acct_port
    server.auth_port = server.default_auth_port
    server.accounting = server.default_accounting
    server.authentication = server.default_authentication
    server2.acct_port = server2.default_acct_port
    server2.auth_port = server2.default_auth_port
    server2.accounting = server2.default_accounting
    server2.authentication = server2.default_authentication
    assert_equal(server.acct_port, server.default_acct_port)
    assert_equal(server.auth_port, server.default_auth_port)
    assert_equal(server.accounting, server.default_accounting)
    assert_equal(server.authentication, server.default_authentication)
    assert_equal(server2.acct_port, server2.default_acct_port)
    assert_equal(server2.auth_port, server2.default_auth_port)
    assert_equal(server2.accounting, server2.default_accounting)
    assert_equal(server2.authentication, server2.default_authentication)

    server.destroy
    server2.destroy
    refute_includes(Cisco::RadiusServer.radiusservers, id)
    refute_includes(Cisco::RadiusServer.radiusservers, id2)
  end
end
