# NTP Config provider class
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
  # NtpConfig - node utility class for NTP Config configuration management
  class NtpConfig < NodeUtil
    attr_reader :name

    def initialize(name)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError,
           "This provider only accepts an id of 'default'" \
           unless name.eql?('default')
      @name = name
    end

    def self.ntpconfigs
      hash = {}
      hash['default'] = NtpConfig.new('default')
      hash
    end

    def ==(other)
      name == other.name
    end

    def source_interface
      source_interface = config_get('ntp_config', 'source_interface')
      source_interface = source_interface.downcase \
                          unless source_interface.nil?
      source_interface
    end

    def source_interface=(val)
      if val.nil? && !source_interface.nil?
        config_set('ntp_config',
                   'source_interface',
                   state:            'no',
                   source_interface: source_interface)
      elsif !val.nil?
        config_set('ntp_config',
                   'source_interface',
                   state:            '',
                   source_interface: val)
      end
    end
  end # class
end # module
