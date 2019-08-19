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

module Cisco
  # node_utils class for interface_evpn_multisite
  class InterfaceEvpnMultisite < NodeUtil
    attr_reader :interface, :show_name, :tracking

    def initialize(interface, show_name=nil)
      fail TypeError unless interface.is_a?(String)
      @interface = interface.downcase
      @show_name = show_name.nil? ? '' : Utils.normalize_intf_pattern(show_name)
      @get_args = @set_args = { interface: @interface, show_name: @show_name }
    end

    def self.interfaces(show_name=nil)
      hash = {}
      show_name = Utils.normalize_intf_pattern(show_name)
      begin
        intf_list = config_get('interface_evpn_multisite', 'all_interfaces',
                               show_name: show_name)
      rescue CliError => e
        raise unless show_name
        # ignore logical interfaces that do not exist
        debug 'InterfaceEvpnMultisite.interfaces ignoring CliError => ' + e.to_s
      end
      return hash if intf_list.nil?

      intf_list.each do |id|
        id = id.downcase
        intf = InterfaceEvpnMultisite.new(id, show_name)
        hash[id] = intf if intf.tracking
      end
      hash
    end

    def enable(tracking)
      @set_args[:tracking] = tracking
      @set_args[:state] = ''
      config_set('interface_evpn_multisite', 'evpn_multisite', @set_args)
    end

    def disable(tracking='dci-tracking')
      @set_args[:tracking] = tracking
      @set_args[:state] = 'no'
      config_set('interface_evpn_multisite', 'evpn_multisite', @set_args)
    end

    def tracking
      config_get('interface_evpn_multisite', 'evpn_multisite', @get_args)
    end

    def tracking=(tracking)
      enable(tracking)
    end
  end # class
end # module
