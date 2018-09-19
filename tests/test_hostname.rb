#
# Minitest for HostName class
#
# Copyright (c) 2014-2018 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/hostname'

# TestHostname - Minitest for SyslogSetting node utility.
class TestHostName < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    hostname_setup
  end

  def teardown
    # teardown runs at the end of each test
    hostname_teardown
    super
  end

  @current_hostname = ''

  def hostname_setup
    hostname_output = Cisco::Client.filter_cli(
      cli_output: config('show running-config | include ^hostname'),
      value:      /hostname (.*)/)
    @current_hostname = hostname_output.first unless hostname_output.nil?
    # Turn the feature off for a clean test.
    config('no hostname')
  end

  def hostname_teardown
    if @current_hostname != ''
      config("hostname #{@current_hostname}")
    else
      config('no hostname')
    end
  end

  # TESTS

  def test_hostname_name
    hostname_setting = Cisco::HostName.new('testhost')
    assert_equal(Cisco::HostName.hostname['testhost'], hostname_setting)
    hostname_setting = Cisco::HostName.new('testhost2')
    assert_equal(Cisco::HostName.hostname['testhost2'], hostname_setting)
    hostname_setting.send('hostname=', nil)
    assert_nil(Cisco::HostName.hostname['testhost2'])
  end
end
