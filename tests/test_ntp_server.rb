#
# Minitest for NtpServer class
#
# Copyright (c) 2014-2017 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/ntp_server'

# TestNtpServer - Minitest for NtpServer node utility.
class TestNtpServer < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_ntpserver
  end

  def teardown
    # teardown runs at the end of each test
    no_ntpserver
    super
  end

  def no_ntpserver
    # Turn the feature off for a clean test.
    config('no ntp server 130.88.203.12',
           'no ntp server 2003::5',
           'no ntp server 0.us.pool.ntp.org',
           'no ntp authentication-key 999 md5 test 7',
           'no vrf context red')
  end

  # TESTS

  def test_create_name_invalid
    assert_raises(ArgumentError) do
      Cisco::NtpServer.new({ 'name' => '1_com' }, true)
    end
  end

  def test_ipv4
    id = '130.88.203.12'
    refute_includes(Cisco::NtpServer.ntpservers, id)

    ntp = Cisco::NtpServer.new({ 'name' => id }, true)
    assert_includes(Cisco::NtpServer.ntpservers, id)
    assert_equal(ntp, Cisco::NtpServer.ntpservers[id])

    ntp.destroy
    refute_includes(Cisco::NtpServer.ntpservers, id)
  end

  def test_ipv6
    id = '2003::5'
    refute_includes(Cisco::NtpServer.ntpservers, id)

    ntp = Cisco::NtpServer.new({ 'name' => id }, true)
    assert_includes(Cisco::NtpServer.ntpservers, id)
    assert_equal(ntp, Cisco::NtpServer.ntpservers[id])

    ntp.destroy
    refute_includes(Cisco::NtpServer.ntpservers, id)
  end

  def test_multiple
    id1 = '130.88.203.12'
    id2 = '2003::5'
    refute_includes(Cisco::NtpServer.ntpservers, id1)
    refute_includes(Cisco::NtpServer.ntpservers, id2)

    ntp1 = Cisco::NtpServer.new({ 'name' => id1 }, true)
    ntp2 = Cisco::NtpServer.new({ 'name' => id2 }, true)
    refute_equal(ntp1, ntp2)
    assert_includes(Cisco::NtpServer.ntpservers, id1)
    assert_includes(Cisco::NtpServer.ntpservers, id2)
    assert_equal(ntp1, Cisco::NtpServer.ntpservers[id1])
    assert_equal(ntp2, Cisco::NtpServer.ntpservers[id2])

    ntp1.destroy
    ntp2.destroy
    refute_includes(Cisco::NtpServer.ntpservers, id1)
    refute_includes(Cisco::NtpServer.ntpservers, id2)
  end

  # This test requires DNS resolution be avaabile - leaving for reference
  # def test_domain_name
  #   id = '0.us.pool.ntp.org'
  #   refute_includes(Cisco::NtpServer.ntpservers, id)
  #
  #   ntp = Cisco::NtpServer.new({ 'name' => id }, true)
  #   assert_includes(Cisco::NtpServer.ntpservers, id)
  #   assert_equal(ntp, Cisco::NtpServer.ntpservers[id])
  #
  #   ntp.destroy
  #   refute_includes(Cisco::NtpServer.ntpservers, id)
  # end

  def test_defaults
    id = '130.88.203.12'
    refute_includes(Cisco::NtpServer.ntpservers, id)

    ntp = Cisco::NtpServer.new({ 'name' => id }, true)
    assert_includes(Cisco::NtpServer.ntpservers, id)
    assert_equal('default', Cisco::NtpServer.ntpservers[id].vrf)
    assert_nil(Cisco::NtpServer.ntpservers[id].key)
    assert_nil(Cisco::NtpServer.ntpservers[id].maxpoll)
    assert_nil(Cisco::NtpServer.ntpservers[id].minpoll)
    refute(Cisco::NtpServer.ntpservers[id].prefer)

    ntp.destroy
    refute_includes(Cisco::NtpServer.ntpservers, id)
  end

  def test_create_options
    id = '130.88.203.12'
    refute_includes(Cisco::NtpServer.ntpservers, id)

    options = { 'name' => id, 'key' => '999', 'prefer' => 'true',
                'minpoll' => '5', 'maxpoll' => '8', 'vrf' => 'red' }

    config('vrf context red')
    config('ntp authentication-key 999 md5 test 7')

    ntp = Cisco::NtpServer.new(options, true)
    assert_includes(Cisco::NtpServer.ntpservers, id)
    assert_equal('red', Cisco::NtpServer.ntpservers[id].vrf)
    assert_equal('999', Cisco::NtpServer.ntpservers[id].key)
    assert_equal('5', Cisco::NtpServer.ntpservers[id].minpoll)
    assert_equal('8', Cisco::NtpServer.ntpservers[id].maxpoll)
    assert(Cisco::NtpServer.ntpservers[id].prefer)

    ntp.destroy
    refute_includes(Cisco::NtpServer.ntpservers, id)
  end
end
