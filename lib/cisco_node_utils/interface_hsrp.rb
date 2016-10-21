# November 2016, Sai Chintalapudi
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
require_relative 'interface'

module Cisco
  # InterfaceHsrp - node utility class for interface hsrp management
  class InterfaceHsrp < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name.length > 0
      @name = name.downcase

      set_args_keys_default
      create if instantiate
    end

    def to_s
      "interface_hsrp #{name}"
    end

    def self.interfaces
      hash = {}
      intf_list = config_get('interface', 'all_interfaces')
      return hash if intf_list.nil?

      intf_list.each do |id|
        id = id.downcase
        hash[id] = InterfaceHsrp.new(id, false)
      end
      hash
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      keys = { name: @name }
      @get_args = @set_args = keys
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    def create
      Feature.hsrp_enable
      config_set('interface_hsrp', 'create', name: @name)
    end

    def destroy
      config_set('interface_hsrp', 'destroy', name: @name)
      set_args_keys_default
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def bfd
      config_get('interface_hsrp', 'bfd', @get_args)
    end

    def bfd=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      Feature.bfd_enable if val
      config_set('interface_hsrp', 'bfd', @set_args)
    end

    def default_bfd
      config_get_default('interface_hsrp', 'bfd')
    end

    # hsrp delay minimum and reload are in the same CLI
    # hsrp delay minimum 0 reload 0
    def delay_minimum
      match = config_get('interface_hsrp', 'delay', @get_args)
      match.nil? ? default_delay_minimum : match[0].to_i
    end

    def delay_minimum=(val)
      set_args_keys(minimum: 'minimum', min: val, reload: '', rel: '')
      config_set('interface_hsrp', 'delay', @set_args)
    end

    def default_delay_minimum
      config_get_default('interface_hsrp', 'delay_minimum')
    end

    # hsrp delay minimum and reload are in the same CLI
    # hsrp delay minimum 0 reload 0
    def delay_reload
      match = config_get('interface_hsrp', 'delay', @get_args)
      match.nil? ? default_delay_reload : match[1].to_i
    end

    # hsrp delay minimum and reload are in the same CLI
    # but both can be set independent of each other
    def delay_reload=(val)
      set_args_keys(minimum: '', min: '', reload: 'reload', rel: val)
      config_set('interface_hsrp', 'delay', @set_args)
    end

    def default_delay_reload
      config_get_default('interface_hsrp', 'delay_reload')
    end

    def mac_refresh
      config_get('interface_hsrp', 'mac_refresh', @get_args)
    end

    def mac_refresh=(val)
      state = val ? '' : 'no'
      time = val ? val : ''
      set_args_keys(state: state, timeout: time)
      config_set('interface_hsrp', 'mac_refresh', @set_args)
    end

    def default_mac_refresh
      config_get_default('interface_hsrp', 'mac_refresh')
    end

    def use_bia
      match = config_get('interface_hsrp', 'use_bia', @get_args)
      return default_use_bia unless match
      match.include?('scope') ? :use_bia_intf : :use_bia
    end

    def use_bia=(val)
      return if val == use_bia
      # need to reset before set
      if val
        if val == :use_bia
          set_args_keys(state: 'no', scope: ' scope interface')
          config_set('interface_hsrp', 'use_bia', @set_args)
          set_args_keys(state: '', scope: '')
          config_set('interface_hsrp', 'use_bia', @set_args)
        else
          set_args_keys(state: 'no', scope: '')
          config_set('interface_hsrp', 'use_bia', @set_args)
          set_args_keys(state: '', scope: ' scope interface')
          config_set('interface_hsrp', 'use_bia', @set_args)
        end
      else
        if use_bia == :use_bia
          set_args_keys(state: 'no', scope: '')
          config_set('interface_hsrp', 'use_bia', @set_args)
        else
          set_args_keys(state: 'no', scope: ' scope interface')
          config_set('interface_hsrp', 'use_bia', @set_args)
        end
      end
    end

    def default_use_bia
      config_get_default('interface_hsrp', 'use_bia')
    end

    def version
      config_get('interface_hsrp', 'version', @get_args)
    end

    def version=(val)
      set_args_keys(ver: val)
      config_set('interface_hsrp', 'version', @set_args)
    end

    def default_version
      config_get_default('interface_hsrp', 'version')
    end
  end # class
end # module
