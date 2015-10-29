#
# NXAPI implementation of Fabricpath Global class
#
# November 2015, Deepak Cherian
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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

require File.join(File.dirname(__FILE__), 'node_util')

module Cisco
  # node_utils class for fabricpath_global
  class FabricpathGlobal < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name == "default"
      @name = name.downcase

      create if instantiate
    end

    def self.globals
      hash = {}
      is_fabricpath_feature = config_get('fabricpath', 'feature')
      return hash if (:enabled != is_fabricpath_feature.first.to_sym)
      hash['default'] = FabricpathGlobal.new('default', false)
      hash
    end

    def fabricpath_feature
      fabricpath = config_get('fabricpath', 'feature')
      fail 'fabricpath_feature not found' if fabricpath.nil?
      return :disabled if fabricpath.nil?
      fabricpath.shift.to_sym
    end

    def fabricpath_feature_set(fabricpath_set)
      curr = fabricpath_feature
      return if curr == fabricpath_set

      case fabricpath_set
      when :enabled
        config_set('fabricpath', 'feature_install', '') if curr == :uninstalled
        config_set('fabricpath', 'feature', '')
      when :disabled
        config_set('fabricpath', 'feature', 'no') if curr == :enabled
        return
      when :installed
        config_set('fabricpath', 'feature_install', '') if curr == :uninstalled
      when :uninstalled
        config_set('fabricpath', 'feature', 'no') if curr == :enabled
        config_set('fabricpath', 'feature_install', 'no')
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def create
      fabricpath_feature_set(:enabled) unless :enabled == fabricpath_feature
    end

    def destroy
      @name = nil
      fabricpath_feature_set(:disabled)
    end

    def my_munge(property, set_val)
      val = config_get_default('supported', property)
      case property
      when /loadbalance_algorithm/
        if (val == 'source-destination') && (set_val == 'symmetric' || set_val == 'xor')
          val
        else
          set_val
        end
      when /loadbalance_.*_rotate/
        if val == false || set_val == ''
          ''
        else
          "rotate-amount 0x#{set_val.to_s(16)}"
        end
      else
        set_val
      end
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def aggregate_multicast_routes
      agg_routes = config_get('fabricpath', 'aggregate_multicast_routes')
      return default_aggregate_multicast_routes if agg_routes.nil?
      agg_routes.first == 'aggregate-routes' ? true : false
    end

    def aggregate_multicast_routes=(val)
      if (val == true)
        config_set('fabricpath', 'aggregate_multicast_routes', '')
      else
        config_set('fabricpath', 'aggregate_multicast_routes', 'no')
      end
    rescue Cisco::CliError => e
      raise "[Setting agg-routes #{val}] '#{e.command}' : #{e.clierror}"
    end

    def default_aggregate_multicast_routes
      config_get_default('fabricpath', 'aggregate_multicast_routes')
    end

    def allocate_delay
      delay = config_get('fabricpath', 'allocate_delay')
      return default_allocate_routes if delay.nil?
      delay.first.to_i
    end

    def allocate_delay=(val)
      if val == ''
        config_set('fabricpath', 'allocate_delay', 'no', '')
      else
        config_set('fabricpath', 'allocate_delay', '', val)
      end
    rescue Cisco::CliError => e
      raise "[Setting allocate-delay #{val}] '#{e.command}' : #{e.clierror}"
    end

    def default_allocate_delay
      config_get_default('fabricpath', 'allocate_delay')
    end

    def graceful_merge
      graceful_merge_conf = config_get('fabricpath', 'graceful_merge')
      return default_graceful_merge if graceful_merge_conf.nil?
      graceful_merge_conf.first == 'disable' ? false : true
    end

    def auto_switch_id
      val = config_get('fabricpath', 'auto_switch_id')
      val.first.to_i
    end

    def graceful_merge=(val)
      if val == '' || val == true
        config_set('fabricpath', 'graceful_merge', 'no')
      else
        config_set('fabricpath', 'graceful_merge', '')
      end
    rescue Cisco::CliError => e
      raise "[Setting allocate-delay #{val}] '#{e.command}' : #{e.clierror}"
    end

    def default_graceful_merge
      config_get_default('fabricpath', 'graceful_merge')
    end

    def linkup_delay
      delay = config_get('fabricpath', 'linkup_delay')
      return default_linkup_delay if delay.nil?
      delay.first.to_i
    end

    def linkup_delay=(val)
      if val == ''
        config_set('fabricpath', 'linkup_delay', 'no', '')
      else
        config_set('fabricpath', 'linkup_delay', '', val)
      end
    rescue Cisco::CliError => e
      raise "[Setting linkup-delay #{val}] '#{e.command}' : #{e.clierror}"
    end

    def default_linkup_delay
      config_get_default('fabricpath', 'linkup_delay')
    end

    def linkup_delay_always
      enabled = config_get('fabricpath', 'linkup_delay_always')
      return default_linkup_delay_always if enabled.nil?
      enabled.first.strip == 'always' ? true : false
    end

    def linkup_delay_always=(val)
      if val == '' || val == true
        config_set('fabricpath', 'linkup_delay_always', '')
      else
        config_set('fabricpath', 'linkup_delay_always', 'no')
      end
    rescue Cisco::CliError => e
      raise "[Setting linkup-delay-always #{val}] '#{e.command}'
            : #{e.clierror}"
    end

    def default_linkup_delay_always
      config_get_default('fabricpath', 'linkup_delay_always')
    end

    def linkup_delay_enable
      enabled = config_get('fabricpath', 'linkup_delay_enable')
      return default_linkup_delay_enable if enabled.nil?
      enabled.first.strip == 'Enabled' ? true : false
    end

    def linkup_delay_enable=(val)
      if val == '' || val == true
        config_set('fabricpath', 'linkup_delay_enable', '')
      else
        config_set('fabricpath', 'linkup_delay_enable', 'no')
      end
    rescue Cisco::CliError => e
      raise "[Setting linkup-delay-enable #{val}] '#{e.command}'
            : #{e.clierror}"
    end

    def default_linkup_delay_enable
      config_get_default('fabricpath', 'linkup_delay_enable')
    end

    def loadbalance_algorithm
      algo = config_get('fabricpath', 'loadbalance_algorithm')
      return default_loadbalance_algorithm if algo.nil?
      algo.first.strip.downcase
    end

    def loadbalance_algorithm=(val)
      val = my_munge('loadbalance_algorithm', val)
      if val == ''
        config_set('fabricpath', 'loadbalance_algorithm', 'no', '')
      else
        config_set('fabricpath', 'loadbalance_algorithm', '', val)
      end
    rescue Cisco::CliError => e
      raise "[Setting loadbalance-algo #{val}] '#{e.command}' : #{e.clierror}"
    end

    def default_loadbalance_algorithm
      config_get_default('fabricpath', 'loadbalance_algorithm')
    end

    def loadbalance_multicast_rotate
      multicast = config_get('fabricpath', 'loadbalance_multicast_rotate')
      return default_loadbalance_multicast_rotate if multicast.nil?
      multicast.first.to_i
    end

    def loadbalance_multicast_has_vlan
      multicast = config_get('fabricpath', 'loadbalance_multicast_has_vlan')
      return default_loadbalance_multicast_has_vlan if multicast.nil?
      multicast.first.strip == 'TRUE' ? true : false
    end

    def loadbalance_multicast=(rotate, has_vlan)
      if rotate == '' && (has_vlan == '' || has_vlan == false)
        config_set('fabricpath', 'loadbalance_multicast_reset')
      else
        rotate = my_munge('loadbalance_multicast_rotate', rotate)
        has_vlan = (has_vlan == true) ? "include-vlan" : ''
        config_set('fabricpath', 'loadbalance_multicast_set', 
                   rotate_amt: rotate, inc_vlan: has_vlan)
      end
    rescue Cisco::CliError => e
      raise "[Setting loadbalance #{rotate} #{has_vlan}] '#{e.command}' 
             : #{e.clierror}"
    end

    def default_loadbalance_multicast_rotate
      config_get_default('fabricpath', 'loadbalance_multicast_rotate')
    end

    def default_loadbalance_multicast_has_vlan
      config_get_default('fabricpath', 'loadbalance_multicast_has_vlan')
    end

    def loadbalance_unicast_layer
      unicast = config_get('fabricpath', 'loadbalance_unicast_layer')
      return default_loadbalance_unicast_layer if unicast.nil?
      case unicast.first.strip
      when /L4/
        "layer4"
      when /L3/
        "layer3"
      when /Mixed/
        "mixed"
      end
    end

    def loadbalance_unicast_rotate
      unicast = config_get('fabricpath', 'loadbalance_unicast_rotate')
      return default_loadbalance_unicast_rotate if unicast.nil?
      unicast.first.to_i
    end

    def loadbalance_unicast_has_vlan
      unicast = config_get('fabricpath', 'loadbalance_unicast_has_vlan')
      return default_loadbalance_unicast_has_vlan if unicast.nil?
      unicast.first.strip == 'TRUE' ? true : false
    end

    def split_loadbalance_unicast_layer=(val)
      if val == ''
        config_set('fabricpath', 'loadbalance_unicast_layer', 'no', val)
      else
        config_set('fabricpath', 'loadbalance_unicast_layer', '', val)
      end
      rescue Cisco::CliError => e
        raise "[Setting loadbalance layer #{val} ] '#{e.command}'
              : #{e.clierror}"
    end

    def split_loadbalance_unicast_rotate=(val)
      if val == ''
        config_set('fabricpath', 'loadbalance_unicast_rotate', 'no', val)
      else
        config_set('fabricpath', 'loadbalance_unicast_rotate', '', val)
      end
      rescue Cisco::CliError => e
        raise "[Setting loadbalance rotate #{val} ] '#{e.command}'
              : #{e.clierror}"
    end

    def split_loadbalance_unicast_has_vlan=(val)
      if val == '' || val == false
        config_set('fabricpath', 'loadbalance_unicast_has_vlan', 'no')
      else
        config_set('fabricpath', 'loadbalance_unicast_has_vlan', '')
      end
      rescue Cisco::CliError => e
        raise "[Setting loadbalance has_vlan #{val} ] '#{e.command}'
              : #{e.clierror}"
    end

    def loadbalance_unicast=(layer, rotate, has_vlan)
      support = config_get_default('supported', 'loadbalance_unicast')
      if support == 'combined'
        if layer == '' && rotate == '' && (has_vlan == '' || has_vlan == false)
          config_set('fabricpath', 'loadbalance_unicast_reset')
        else
          rotate = my_munge('loadbalance_unicast_rotate', rotate)
          has_vlan = (has_vlan == true) ? "include-vlan" : ''
          config_set('fabricpath', 'loadbalance_unicast_set', 
                     pref: layer, rotate_amt: rotate, inc_vlan: has_vlan)
        end
     else
       split_loadbalance_unicast_layer = layer
       split_loadbalance_unicast_rotate = rotate
       split_loadbalance_unicast_has_vlan = has_vlan
     end
    rescue Cisco::CliError => e
      raise "[Setting loadbalance #{layer} #{rotate} #{has_vlan}] '#{e.command}'
            : #{e.clierror}"
    end

    def default_loadbalance_unicast_layer
      config_get_default('fabricpath', 'loadbalance_unicast_layer')
    end

    def default_loadbalance_unicast_rotate
      config_get_default('fabricpath', 'loadbalance_unicast_rotate')
    end

    def default_loadbalance_unicast_has_vlan
      config_get_default('fabricpath', 'loadbalance_unicast_has_vlan')
    end

    def mode
      mode_conf = config_get('fabricpath', 'mode')
      return default_mode if mode_conf.nil?
      mode_conf.first
    end

    def mode=(val)
      if val == '' || val == 'normal'
        config_set('fabricpath', 'mode', 'no')
      else
        config_set('fabricpath', 'mode', '')
      end
    rescue Cisco::CliError => e
      raise "[Setting mode #{val}] '#{e.command}' : #{e.clierror}"
    end

    def default_mode
      config_get_default('fabricpath', 'mode')
    end

    def switch_id
      switch_id_conf = config_get('fabricpath', 'switch_id')
      return auto_switch_id if switch_id_conf.nil?
      switch_id_conf.first.to_i
    end

    def switch_id=(val)
      # There is no no-form for this command
      config_set('fabricpath', 'switch_id', val.to_s)
    rescue Cisco::CliError => e
      raise "[Setting switch-id #{val}] '#{e.command}' : #{e.clierror}"
    end

    def transition_delay
      delay = config_get('fabricpath', 'transition_delay')
      return default_transition_delay if delay.nil?
      delay.first.to_i
    end

    def transition_delay=(val)
      if val == ''
        config_set('fabricpath', 'transition_delay', 'no', '')
      else
        config_set('fabricpath', 'transition_delay', '', val)
      end
    rescue Cisco::CliError => e
      raise "[Setting linkup-delay #{val}] '#{e.command}' : #{e.clierror}"
    end

    def default_transition_delay
      config_get_default('fabricpath', 'transition_delay')
    end

  end # class
end # module
