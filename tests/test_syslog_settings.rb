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
    return if platform != :nexus
    # setup runs at the beginning of each test
    super
    default_syslogsettings
  end

  def teardown
    return if platform != :nexus
    # teardown runs at the end of each test
    default_syslogsettings
    super
  end

  def default_syslogsettings
    # Turn the feature off for a clean test.
    config('no logging timestamp seconds',
           'logging console 2',
           'logging monitor 5',
           'no logging source-interface',
           'no logging logfile')
  end

  # TESTS

  def test_timestamp
    syslog_setting = Cisco::SyslogSettings.new('default')

    if platform == :ios_xr
      assert_nil(syslog_setting.timestamp)
      assert_raises(Cisco::UnsupportedError) do
        syslog_setting.timestamp = 'milliseconds'
      end
    else
      assert_includes(Cisco::SyslogSettings.syslogsettings, 'default')
      assert_equal(syslog_setting,
                   Cisco::SyslogSettings.syslogsettings['default'],
                  )

      syslog_setting.timestamp = 'milliseconds'
      assert_equal('milliseconds',
                   Cisco::SyslogSettings.syslogsettings['default'].timestamp,
                  )
      assert_equal('milliseconds',
                   syslog_setting.timestamp,
                  )
      syslog_setting.time_stamp_units = 'seconds'
      assert_equal('seconds',
                   syslog_setting.time_stamp_units,
                  )
    end
  end

  def test_console
    syslog_setting = Cisco::SyslogSettings.new('default')

    # Some systems return the value and othesr get it from yaml - normalize
    assert_equal(syslog_setting.default_console, syslog_setting.console.to_i)
    assert_equal(2, syslog_setting.console)
    syslog_setting.console = '1'
    assert_equal('1', syslog_setting.console)
    syslog_setting.console = nil
    assert_equal('unset', syslog_setting.console)
  end

  def test_monitor
    syslog_setting = Cisco::SyslogSettings.new('default')

    # Some systems return the value and othesr get it from yaml - normalize
    assert_equal(syslog_setting.default_monitor, syslog_setting.monitor.to_i)
    assert_equal('5', syslog_setting.monitor)
    syslog_setting.monitor = '7'
    assert_equal('7', syslog_setting.monitor)
    syslog_setting.monitor = nil
    assert_equal('unset', syslog_setting.monitor)
  end

  def test_source_interface
    syslog_setting = Cisco::SyslogSettings.new('default')

    assert_nil(syslog_setting.source_interface)
    syslog_setting.source_interface = 'mgmt0'
    assert_equal('mgmt0', syslog_setting.source_interface)
    syslog_setting.source_interface = nil
    assert_nil(syslog_setting.source_interface)
  end

  def test_logfile
    syslog_setting = Cisco::SyslogSettings.new('default')

    assert_equal('unset', syslog_setting.logfile_name)
    syslog_setting.send('logfile_name=', 'testlog', 5, 'size 4097')
    assert_equal('testlog', syslog_setting.logfile_name)
    assert_equal('5', syslog_setting.logfile_severity_level)
    assert_equal('4097', syslog_setting.logfile_size)
    syslog_setting.send('logfile_name=', nil, nil, nil)
    assert_equal('unset', syslog_setting.logfile_name)
    assert_nil(syslog_setting.logfile_severity_level)
    assert_nil(syslog_setting.logfile_size)
  end
end
