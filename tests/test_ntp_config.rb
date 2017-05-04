#
# Minitest for NtpConfig class
#
# Copyright (c) 2015-2017 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/ntp_config'

# TestNtpConfig - Minitest for NtpConfig node utility.
class TestNtpConfig < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_ntpconfig
  end

  def teardown
    # teardown runs at the end of each test
    no_ntpconfig
    super
  end

  def no_ntpconfig
    # Turn the feature off for a clean test.
    if platform == :ios_xr
      config("no ntp source #{interfaces[1]}")
    else
      config("no ntp source-interface #{interfaces[1]}",
             'no ntp authentication-key 111 md5 test 7',
             'no ntp authentication-key 999 md5 test 7',
             'no ntp trusted-key 111',
             'no ntp trusted-key 999',
             'no ntp authenticate')
    end
  end

  # TESTS

  def test_source_interface
    id = 'default'

    ntp = Cisco::NtpConfig.new(id)
    assert_includes(Cisco::NtpConfig.ntpconfigs, id)
    assert_equal(Cisco::NtpConfig.ntpconfigs[id], ntp)

    assert_nil(Cisco::NtpConfig.ntpconfigs[id].source_interface)
    assert_nil(ntp.source_interface)

    ntp.source_interface = interfaces[1]
    assert_equal(Cisco::NtpConfig.ntpconfigs[id].source_interface,
                 interfaces[1].downcase)
    assert_equal(Cisco::NtpConfig.ntpconfigs[id].source_interface,
                 ntp.source_interface)

    ntp.source_interface = nil
    assert_nil(Cisco::NtpConfig.ntpconfigs[id].source_interface)
    assert_nil(ntp.source_interface)
  end

  def test_authenticate
    id = 'default'

    ntp = Cisco::NtpConfig.new(id)
    assert_includes(Cisco::NtpConfig.ntpconfigs, id)
    assert_equal(Cisco::NtpConfig.ntpconfigs[id], ntp)

    assert_equal(false, Cisco::NtpConfig.ntpconfigs[id].authenticate)

    ntp.authenticate = true
    assert_equal(true, Cisco::NtpConfig.ntpconfigs[id].authenticate)
  end

  def test_trusted_key
    id = 'default'

    ntp = Cisco::NtpConfig.new(id)
    assert_includes(Cisco::NtpConfig.ntpconfigs, id)
    assert_equal(Cisco::NtpConfig.ntpconfigs[id], ntp)

    assert_nil(Cisco::NtpConfig.ntpconfigs[id].trusted_key)

    config('ntp authentication-key 111 md5 test 7',
           'ntp authentication-key 999 md5 test 7')
    ntp.trusted_key_set(true, 111)
    ntp.trusted_key_set(true, 999)
    assert_equal(%w(111 999), Cisco::NtpConfig.ntpconfigs[id].trusted_key)
  end
end
