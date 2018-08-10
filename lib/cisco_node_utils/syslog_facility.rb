# Syslog facility provider class
#
# Rick Sherman et al., August 2018
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

require_relative 'node_util'

module Cisco
  # SyslogFacility - node utility class for Syslog facility severity management
  class SyslogFacility < NodeUtil
    attr_reader :facility, :level

    def initialize(opts, instantiate=true)
      @facility = opts['facility']
      @level = opts['level']

      create if instantiate
    end

    def self.facilities
      keys = %w(facility level)
      hash = {}
      facility_key_list = config_get('syslog_facility', 'facility')
      return hash if facility_key_list.nil?

      facility_key_list.each do |id|
        hash[id[0]] = SyslogFacility.new(Hash[keys.zip(id)], false)
      end

      hash
    end

    def ==(other)
      facility == other.facility && level == other.level
    end

    def create
      config_set('syslog_facility', 'facility', state: '', facility: @facility,
                  level: @level)
    end

    def destroy
      config_set('syslog_facility', 'facility', state: 'no',
                  facility: @facility, level: @level)
    end

    def level
      @level.to_i
    end
  end # class
end # module
