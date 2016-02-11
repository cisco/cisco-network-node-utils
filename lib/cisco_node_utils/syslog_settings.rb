# Syslog Settings provider class
#
# Jonathan Tripathy et al., September 2015
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

    def timestamp
      config_get('syslog_settings', 'timestamp')
    end

    def timestamp=(val)
      fail TypeError unless val.is_a?(String)
      fail TypeError \
        unless %w(seconds milliseconds).include?(timestamp)

      # There is no unset version as timestamp has a default value
      config_set('syslog_settings',
                 'timestamp',
                 state: '',
                 units: val)
    end
  end # class
end # module
