#
# Minitest for NtpServer class
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
require File.expand_path('../../lib/cisco_node_utils/ntp_server', __FILE__)

# TestNtpServer - Minitest for NtpServer node utility.
class TestNtpServer < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_ntpserver_uk
  end

  def teardown
    # teardown runs at the end of each test
    no_ntpserver_uk
    super
  end

  def no_ntpserver_uk
    # Turn the feature off for a clean test.
    @device.cmd('conf t ; no ntpserver 130.88.203.12 ; end')
    @device.cmd('conf t ; no ntpserver 194.207.34.9 ; end')
    # Flush the cache since we've modified the device outside of
    # the node_utils APIs
    node.cache_flush
  end

  # TESTS

  def test_ntpserver_create_destroy_single_ipv4
    id = '130.88.203.12'
    refute_includes(Cisco::NtpServer.ntpservers, id)

    ntp = Cisco::NtpServer.new(id, false)
    assert_includes(Cisco::NtpServer.ntpservers, id)
    assert_equal(Cisco::NtpServer.ntpservers[id], ntp)

    ntp.destroy
    refute_includes(Cisco::NtpServer.ntpservers, id)
  end

  def test_ntpserver_create_destroy_multiple
    id1 = '130.88.203.12'
    id2 = '194.207.34.9'
    refute_includes(Cisco::NtpServer.ntpservers, id1)
    refute_includes(Cisco::NtpServer.ntpservers, id2)

    ntp1 = Cisco::NtpServer.new(id1, false)
    ntp2 = Cisco::NtpServer.new(id2, true)
    refute_equal(ntp1, ntp2)
    assert_includes(Cisco::NtpServer.ntpservers, id1)
    assert_includes(Cisco::NtpServer.ntpservers, id2)
    assert_equal(Cisco::NtpServer.ntpservers[id1], ntp1)
    assert_equal(Cisco::NtpServer.ntpservers[id2], ntp2)

    ntp1.destroy
    ntp2.destroy
    refute_includes(Cisco::NtpServer.ntpservers, id1)
    refute_includes(Cisco::NtpServer.ntpservers, id2)
  end
end
