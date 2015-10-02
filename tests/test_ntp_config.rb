#
# Minitest for NtpConfig class
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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
require File.expand_path('../../lib/cisco_node_utils/ntp_config', __FILE__)

# TestNtpConfig - Minitest for NtpConfig node utility.
class TestNtpConfig < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_ntpconfig
  end

  def no_ntpconfig
    # Turn the feature off for a clean test.
    config("no ntp source-interface #{interfaces[0]}")
  end

  # TESTS

  def test_ntpconfig_create_destroy_single
    id = 'default'

    ntp = Cisco::NtpConfig.new(id)
    assert_includes(Cisco::NtpConfig.NtpConfigs, id)
    assert_equal(Cisco::NtpConfig.NtpConfigs[id], ntp)

    ntp.source_interface = ("#{interface[1]}")
    assert_equal(Cisco::NtpConfig.NtpConfigs[id].source_interface,
                 "#{interface[1]}")
    assert_equal(Cisco::NtpConfig.NtpConfigs[id].source_interface,
                 ntp.source_interface)
  end
end
