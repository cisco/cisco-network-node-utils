# October 2017, Rahul Shenoy
#
# Copyright (c) 2017 Cisco and/or its affiliates.
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

require_relative 'cisco_cmn_utils'
require_relative 'node_util'
require_relative 'feature'

module Cisco
  # node_utils class for evpn_stormcontrol
  class EvpnStormcontrol < NodeUtil
    attr_reader :stormcontrol_type, :level

    def initialize(stormcontrol_type, level, instantiate=true)
      err_msg = 'storm control type must be one of the following:' \
                ' broadcast, multicast or unicast'
      type_list = %w(broadcast multicast unicast)
      fail ArgumentError, err_msg unless type_list.include?(stormcontrol_type)
      @stormcontrol_type = stormcontrol_type

      err_msg = "level must be either a 'String' or an" \
                " 'Integer' object"
      fail ArgumentError, err_msg unless level.is_a?(Integer) ||
                                         level.is_a?(String)
      @level = level.to_i
      @get_args = @set_args = { stormcontrol_type: @stormcontrol_type,
                                level:             @level }
      create if instantiate
    end

    def config_stormcontrol
      stormcontrol_type = @set_args[:stormcontrol_type]
      config_set('evpn_stormcontrol', stormcontrol_type, @set_args)
    end

    def create
      @set_args[:state] = ''
      config_stormcontrol
    end

    def destroy
      @set_args[:state] = 'no'
      config_stormcontrol
    end

    # Creat a hash of all stormcontrol instances
    def self.stormcontrol
      hash = {}
      ['broadcast', 'multicast', 'unicast'].each do |type|
        hash[type] = config_get('evpn_stormcontrol', type)
      end
      hash
    end

    def level
        self.stormcontrol    
    end

    def level=(level)
      err_msg = "level must be either a 'String' or an" \
                " 'Integer' object"
      fail ArgumentError, err_msg unless level.is_a?(Integer) ||
                                         level.is_a?(String)
      @level = level.to_i
      @set_args[:level] = @level
      @set_args[:state] = ''
      config_stormcontrol
    end
  end
end
