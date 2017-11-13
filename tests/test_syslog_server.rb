#
# Minitest for SyslogServer class
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
require_relative '../lib/cisco_node_utils/syslog_server'

# TestSyslogServer - Minitest for SyslogServer node utility.
class TestSyslogServer < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_syslogserver
  end

  def teardown
    # teardown runs at the end of each test
    no_syslogserver
    super
  end

  def no_syslogserver
    # Turn the feature off for a clean test.
    if platform == :ios_xr
      config('no logging 1.2.3.4',
             'no logging 1.2.3.4 vrf red',
             'no logging 2003::2',
             'no logging 2003::2 vrf red',
             'no vrf red')
    else
      config('no logging server 1.2.3.4',
             'no logging server 2003::2',
             'no vrf context red')
    end
  end

  # TESTS

  def test_create_destroy_single_ipv4
    id = '1.2.3.4'
    refute_includes(Cisco::SyslogServer.syslogservers, id)

    server = Cisco::SyslogServer.new({ 'name' => id, 'vrf' => 'default' }, true)
    assert_includes(Cisco::SyslogServer.syslogservers, id)
    assert_equal(server, Cisco::SyslogServer.syslogservers[id])

    server.destroy
    refute_includes(Cisco::SyslogServer.syslogservers, id)
  end

  def test_create_destroy_single_ipv6
    id = '2003::2'
    refute_includes(Cisco::SyslogServer.syslogservers, id)

    server = Cisco::SyslogServer.new({ 'name' => id, 'vrf' => 'default' }, true)
    assert_includes(Cisco::SyslogServer.syslogservers, id)
    assert_equal(server, Cisco::SyslogServer.syslogservers[id])

    server.destroy
    refute_includes(Cisco::SyslogServer.syslogservers, id)
  end

  def test_create_destroy_multiple
    id = '1.2.3.4'
    id2 = '2003::2'
    refute_includes(Cisco::SyslogServer.syslogservers, id)
    refute_includes(Cisco::SyslogServer.syslogservers, id2)

    server = Cisco::SyslogServer.new({ 'name' => id, 'vrf' => 'default' }, true)
    server2 = Cisco::SyslogServer.new({ 'name' => id2, 'vrf' => 'default' },
                                      true)
    assert_includes(Cisco::SyslogServer.syslogservers, id)
    assert_equal(server, Cisco::SyslogServer.syslogservers[id])
    assert_includes(Cisco::SyslogServer.syslogservers, id2)
    assert_equal(server2, Cisco::SyslogServer.syslogservers[id2])

    server.destroy
    server2.destroy
    refute_includes(Cisco::SyslogServer.syslogservers, id)
    refute_includes(Cisco::SyslogServer.syslogservers, id2)
  end

  def test_create_options
    if platform == :ios_xr
      config('vrf red')
    else
      config('vrf context red')
    end

    id = '1.2.3.4'
    options = { 'name' => id, 'level' => '4', 'port' => '2154', 'vrf' => 'red' }

    refute_includes(Cisco::SyslogServer.syslogservers, id)

    server = Cisco::SyslogServer.new(options, true)
    assert_includes(Cisco::SyslogServer.syslogservers, id)
    assert_equal(server, Cisco::SyslogServer.syslogservers[id])
    assert_equal('4', Cisco::SyslogServer.syslogservers[id].level)
    assert_equal('2154', Cisco::SyslogServer.syslogservers[id].port)
    assert_equal('red', Cisco::SyslogServer.syslogservers[id].vrf)

    server.destroy
    refute_includes(Cisco::SyslogServer.syslogservers, id)
  end
end
