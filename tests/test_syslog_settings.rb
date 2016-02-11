#
# Minitest for SyslogSetting class
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
require_relative '../lib/cisco_node_utils/syslog_settings'

# TestSyslogSetting - Minitest for SyslogSetting node utility.
class TestSyslogSettings < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_syslogsettings
  end

  def teardown
    # teardown runs at the end of each test
    no_syslogsettings
    super
  end

  def no_syslogsettings
    # Turn the feature off for a clean test.
    config('no logging timestamp seconds')
  end

  # TESTS

  def test_syslogsettings_create
    syslog_setting = Cisco::SyslogSettings.new('default')
    assert_includes(Cisco::SyslogSettings.syslogsettings, 'default')
    assert_equal(Cisco::SyslogSettings.syslogsettings['default'],
                 syslog_setting)

    syslog_setting.timestamp = 'milliseconds'
    assert_equal(Cisco::SyslogSettings.syslogsettings['default'].timestamp,
                 'milliseconds')
    assert_equal(syslog_setting.timestamp,
                 'milliseconds')
  end
end
