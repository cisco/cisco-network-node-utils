# Syslog Settings provider class
#
# Jonathan Tripathy et al., September 2015
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

require_relative 'node_util'

module Cisco
  # SyslogSettings - node utility class for
  # Syslog Settings configuration management
  class SyslogSettings < NodeUtil
    attr_reader :name

    def initialize(name)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError,
           "This provider only accepts an id of 'default'" \
           unless name.eql?('default')
      @name = name
    end

    def self.syslogsettings
      hash = {}
      hash['default'] = SyslogSettings.new('default')
      hash
    end

    def ==(other)
      name == other.name
    end

    def default_console
      config_get_default('syslog_settings', 'console')
    end

    def console
      console = config_get('syslog_settings', 'console')
      if console.is_a?(Array)
        console = console[0] == 'no' ? 'unset' : console[1]
      end
      console
    end

    def console=(severity)
      if severity
        config_set(
          'syslog_settings', 'console',
          state: '', severity: severity)
      else
        config_set(
          'syslog_settings', 'console',
          state: 'no', severity: '')
      end
    end

    def default_monitor
      config_get_default('syslog_settings', 'monitor')
    end

    def monitor
      monitor = config_get('syslog_settings', 'monitor')
      if monitor.is_a?(Array)
        monitor = monitor[0] == 'no' ? 'unset' : monitor[1]
      end
      monitor
    end

    def monitor=(severity)
      if severity
        config_set(
          'syslog_settings', 'monitor',
          state: '', severity: severity)
      else
        config_set(
          'syslog_settings', 'monitor',
          state: 'no', severity: '')
      end
    end

    def default_source_interface
      config_get_default('syslog_settings', 'source_interface')
    end

    def source_interface
      i = config_get('syslog_settings', 'source_interface')
      i.nil? ? default_source_interface : i.downcase
    end

    def source_interface=(name)
      if name
        config_set(
          'syslog_settings', 'source_interface',
          state: '', source_interface: name)
      else
        config_set(
          'syslog_settings', 'source_interface',
          state: 'no', source_interface: '')
      end
    end

    def timestamp
      config_get('syslog_settings', 'timestamp')
    end

    def timestamp=(val)
      fail TypeError \
        unless %w(seconds milliseconds).include?(val.to_s)

      # There is no unset version as timestamp has a default value
      config_set('syslog_settings',
                 'timestamp',
                 state: '',
                 units: val)
    end

    alias_method :time_stamp_units, :timestamp
    alias_method :time_stamp_units=, :timestamp=
  end # class
end # module
