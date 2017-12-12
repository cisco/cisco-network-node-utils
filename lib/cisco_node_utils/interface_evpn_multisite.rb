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

require_relative 'node_util'
require_relative 'interface'

module Cisco
  # node_utils class for interface_evpn_multisite
  class InterfaceEvpnMultisite < NodeUtil
    attr_reader :interface, :tracking

    def initialize(interface)
      fail TypeError unless interface.is_a?(String)
      @interface = interface.downcase
      @get_args = @set_args = { interface: @interface }
    end

    def self.interfaces
      hash = {}
      intf_list = config_get('interface', 'all_interfaces')
      return hash if intf_list.nil?

      intf_list.each do |id|
        id = id.downcase
        intf = InterfaceEvpnMultisite.new(id, false)
        hash[id] = intf if intf.tracking
      end
      hash
    end

    def enable(tracking)
      @set_args[:tracking] = tracking
      @set_args[:state] = ''
      config_set('interface_evpn_multisite', 'evpn_multisite', @set_args)
    end

    def disable(tracking)
      @set_args[:tracking] = tracking
      @set_args[:state] = 'no'
      config_set('interface_evpn_multisite', 'evpn_multisite', @set_args)
    end

    def tracking
      config_get('interface_evpn_multisite', 'evpn_multisite', @get_args)
    end

    def tracking=(tracking)
      if tracking == default_tracking
        dummy_tracking = 'fabric-tracking'
        disable(dummy_tracking)
      else
        enable(tracking)
      end
    end

    def default_tracking
      config_get_default('interface_evpn_multisite', 'evpn_multisite')
    end
  end # class
end # module
