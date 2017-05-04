#
# Minitest for NtpAuthKey class
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
require_relative '../lib/cisco_node_utils/ntp_auth_key'

# TestNtpAuthKey - Minitest for NtpAuthKey node utility.
class TestNtpAuthKey < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_ntpkey
  end

  def teardown
    # teardown runs at the end of each test
    no_ntpkey
    super
  end

  def no_ntpkey
    # Turn the feature off for a clean test.
    config('no ntp authentication-key 111 md5 test 7',
           'no ntp authentication-key 999 md5 test 7')
  end

  # TESTS

  def test_create_defaults
    id = '111'
    options = { 'name' => id, 'password' => 'test' }
    refute_includes(Cisco::NtpAuthKey.ntpkeys, id)

    key = Cisco::NtpAuthKey.new(options, true)
    assert_includes(Cisco::NtpAuthKey.ntpkeys, id)
    assert_equal(key, Cisco::NtpAuthKey.ntpkeys[id])

    assert_equal(id, Cisco::NtpAuthKey.ntpkeys[id].name)
    assert_equal('md5', Cisco::NtpAuthKey.ntpkeys[id].algorithm)
    assert_equal('7', Cisco::NtpAuthKey.ntpkeys[id].mode)

    key.destroy
    refute_includes(Cisco::NtpAuthKey.ntpkeys, id)
  end

  def test_create_options
    id = '999'
    options = { 'name' => id, 'password' => 'test', 'algorithm' => 'md5',
                'mode' => '7' }
    refute_includes(Cisco::NtpAuthKey.ntpkeys, id)

    key = Cisco::NtpAuthKey.new(options, true)
    assert_includes(Cisco::NtpAuthKey.ntpkeys, id)
    assert_equal(key, Cisco::NtpAuthKey.ntpkeys[id])

    assert_equal(id, Cisco::NtpAuthKey.ntpkeys[id].name)
    assert_equal('md5', Cisco::NtpAuthKey.ntpkeys[id].algorithm)
    assert_equal('7', Cisco::NtpAuthKey.ntpkeys[id].mode)

    key.destroy
    refute_includes(Cisco::NtpAuthKey.ntpkeys, id)
  end
end
