# October 2016, Sai Chintalapudi
#
# Copyright (c) 2016 Cisco and/or its affiliates.
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
  # node_utils class for hsrp_global
  class HsrpGlobal < NodeUtil
    def initialize(instantiate=true)
      Feature.hsrp_enable if instantiate
      set_args_keys_default
    end

    def self.globals
      hash = {}
      hash['default'] = HsrpGlobal.new(false) if Feature.hsrp_enabled?
      hash
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = {}
      @get_args = @set_args
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    def destroy
      return unless Feature.hsrp_enabled?
      [:bfd_all_intf,
       :extended_hold,
      ].each do |prop|
        send("#{prop}=", send("default_#{prop}")) if send prop
      end
      set_args_keys_default
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def bfd_all_intf
      config_get('hsrp_global', 'bfd_all_intf')
    end

    def bfd_all_intf=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      Feature.bfd_enable if val
      config_set('hsrp_global', 'bfd_all_intf', @set_args)
    end

    def default_bfd_all_intf
      config_get_default('hsrp_global', 'bfd_all_intf')
    end

    # CLI can be either of the following or none
    # hsrp timers extended-hold (in this case, the time is 10)
    # hsrp timers extended-hold <time>
    def extended_hold
      hold = config_get('hsrp_global', 'extended_hold', @get_args)
      return default_extended_hold unless hold
      arr = hold.split('hsrp timers extended-hold')
      return config_get('hsrp_global', 'extended_hold_enable', @get_args) if
        arr.empty?
      arr[1].strip
    end

    def extended_hold=(val)
      state = val ? '' : 'no'
      time = val ? val : ''
      set_args_keys(state: state, time: time)
      config_set('hsrp_global', 'extended_hold', @set_args)
    end

    def default_extended_hold
      config_get_default('hsrp_global', 'extended_hold')
    end
  end # class
end # module
