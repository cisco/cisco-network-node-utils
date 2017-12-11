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
  # node_utils class for evpn_multisite
  class EvpnMultisite < NodeUtil
    attr_reader :multisiteid, :time

    def initialize(multisiteid, instantiate=true)
      err_msg = "multisiteid must be either a 'String' or an" \
                " 'Integer' object"
      fail ArgumentError, err_msg unless multisiteid.is_a?(Integer) ||
                                         multisiteid.is_a?(String)
      @multisiteid = multisiteid.to_i
      @get_args = @set_args = { multisiteid: @multisiteid }
      create if instantiate
    end

    def create
      Feature.nv_overlay_enable
      @set_args[:state] = ''
      config_set('evpn_multisite', 'multisite', @set_args)
    end

    def destroy
      @set_args[:state] = 'no'
      # HACK: set time to a dummy value
      @set_args[:time] = 30
      config_set('evpn_multisite', 'delay_restore', @set_args)
      config_set('evpn_multisite', 'multisite', @set_args)
    end

    def self.multisite
      nu_obj = nil
      ms_id = config_get('evpn_multisite', 'multisite')
      nu_obj = EvpnMultisite.new(ms_id, false) if ms_id
      nu_obj
    end

    def multisite
      config_get('evpn_multisite', 'multisite')
    end

    def multisite=(multisiteid)
      err_msg = "multisiteid must be either a 'String' or an" \
                " 'Integer' object"
      fail ArgumentError, err_msg unless multisiteid.is_a?(Integer) ||
                                         multisiteid.is_a?(String)
      @multisiteid = multisiteid.to_i
      @set_args[:multisiteid] = @multisiteid
      config_set('evpn_multisite', 'multisite', @set_args)
    end

    def delay_restore
      config_get('evpn_multisite', 'delay_restore', @get_args)
    end

    def delay_restore=(time)
      # HACK: set a dummy time value when removing the property
      dummy_time = 30
      if time == default_delay_restore
        @set_args[:state] = 'no'
        @set_args[:time] = dummy_time
      else
        @set_args[:time] = time
        @set_args[:state] = '' unless @set_args[:state]
      end
      config_set('evpn_multisite', 'delay_restore', @set_args)
    end

    def default_delay_restore
      config_get_default('evpn_multisite', 'delay_restore')
    end
  end
end
