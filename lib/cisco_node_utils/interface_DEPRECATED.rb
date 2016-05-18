# rubocop: disable Style/FileName
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
###############################################################################
#
#                        WARNING! WARNING! WARNING!
#
# This file contains deprecated methods that will be removed with version 2.0.0
#
###############################################################################

require_relative 'node_util'
require 'logger'

# Cisco provider module
module Cisco
  # Interface - node utility class for general interface config management
  class InterfaceDeprecated < NodeUtil
    PVLAN_PROPERTY = {
      host_promisc:  'switchport_mode_private_vlan_host_promiscous',
      allow_vlan:    'switchport_private_vlan_trunk_allowed_vlan',
      trunk_assoc:   'switchport_private_vlan_association_trunk',
      mapping_trunk: 'switchport_private_vlan_mapping_trunk',
      vlan_mapping:  'private_vlan_mapping',
    }

    def deprecation_warning(method, new_prop=nil)
      if new_prop.nil?
        new_prop = ''
      else
        new_prop = "The new property name is '#{new_prop}'"
      end

      warn "
      #########################################################################
       WARNING: Method '#{method.to_s.delete('=')}'
       is deprecated and should not be used.
       #{new_prop}
      #########################################################################
      "
    end

    def switchport_enable_and_mode_private_vlan_host(mode_set)
      deprecation_warning(__method__)
      switchport_enable unless switchport
      if mode_set[/(host|promiscuous)/]
        config_set('DEPRECATED', 'switchport_mode_private_vlan_host',
                   name: @name, state: '', mode: IF_SWITCHPORT_MODE[mode_set])
      else
        config_set('DEPRECATED', 'switchport_mode_private_vlan_host',
                   name: @name, state: 'no', mode: IF_SWITCHPORT_MODE[mode_set])
      end
    end

    def switchport_mode_private_vlan_host
      mode = config_get('DEPRECATED',
                        'switchport_mode_private_vlan_host',
                        name: @name)
      unless mode == default_switchport_mode_private_vlan_host
        mode = IF_SWITCHPORT_MODE.key(mode)
      end
      mode
    rescue IndexError
      # Assume this is an interface that doesn't support switchport.
      # Do not raise exception since the providers will prefetch this property
      # regardless of interface type.
      # TODO: this should probably be nil instead
      return default_switchport_mode_private_vlan_host
    end

    def switchport_mode_private_vlan_host=(mode_set)
      deprecation_warning(__method__, 'switchport_pvlan_host')

      fail ArgumentError unless IF_SWITCHPORT_MODE.keys.include? mode_set
      Feature.private_vlan_enable
      switchport_enable_and_mode_private_vlan_host(mode_set)
    end

    def default_switchport_mode_private_vlan_host
      config_get_default('DEPRECATED',
                         'switchport_mode_private_vlan_host')
    end

    def switchport_mode_private_vlan_host_association
      result = config_get('DEPRECATED',
                          'switchport_mode_private_vlan_host_association',
                          name: @name)
      unless result == default_switchport_mode_private_vlan_host_association
        result = result[0].split(' ')
      end
      result
    end

    def switchport_mode_private_vlan_host_association=(vlans)
      deprecation_warning(__method__, 'switchport_pvlan_host_association')
      fail TypeError unless vlans.is_a?(Array) || vlans.empty?
      switchport_enable unless switchport
      Feature.private_vlan_enable
      if vlans == default_switchport_mode_private_vlan_host_association
        result = config_set('DEPRECATED',
                            'switchport_mode_private_vlan_host_association',
                            name: @name, state: 'no', vlan_pr: '', vlan_sec: '')

      else
        result = config_set('DEPRECATED',
                            'switchport_mode_private_vlan_host_association',
                            name: @name, state: '',
                            vlan_pr: vlans[0], vlan_sec: vlans[1])

      end
      cli_error_check(result)
    end

    def default_switchport_mode_private_vlan_host_association
      config_get_default('DEPRECATED',
                         'switchport_mode_private_vlan_host_association')
    end

    # This api is used by private vlan to prepare the input to the setter
    # method. The input can be in the following formats for vlans:
    # 10-12,14. Prepare_array api is transforming this input into a flat array.
    # In the example above the returned array will be 10, 11, 12, 13. Prepare
    # array is first splitting the input on ',' and the than expanding the vlan
    # range element like 10-12 into a flat array. The final result will
    # be a  flat array.
    # This way we can later used the lib utility to check the delta from
    # the input vlan value and the vlan configured to apply the right config.
    def prepare_array(is_list)
      new_list = []
      is_list.each do |item|
        if item.include?(',')
          new_list.push(item.split(','))
        else
          new_list.push(item)
        end
      end
      new_list.flatten!
      new_list.sort!
      new_list.each { |item| item.gsub!('-', '..') }
      is_list_new = []
      new_list.each do |elem|
        if elem.include?('..')
          elema = elem.split('..').map { |d| Integer(d) }
          elema.sort!
          tr = elema[0]..elema[1]
          tr.to_a.each do |item|
            is_list_new.push(item.to_s)
          end
        else
          is_list_new.push(elem)
        end
      end
      is_list_new
    end

    def configure_private_vlan_host_property(property, should_list_new,
                                             is_list_new, pr_vlan)
      delta_hash = Utils.delta_add_remove(should_list_new, is_list_new)
      [:add, :remove].each do |action|
        delta_hash[action].each do |vlans|
          state = (action == :add) ? '' : 'no'
          oper = (action == :add) ? 'add' : 'remove'
          if property[/(host_promisc|mapping_trunk)/]

            result = config_set('DEPRECATED', PVLAN_PROPERTY[property],
                                name: @name, state: state,
                                vlan_pr: pr_vlan, vlans: vlans)
            @match_found = true
          end
          if property[/allow_vlan/]
            result = config_set('DEPRECATED',
                                PVLAN_PROPERTY[property],
                                name: @name, state: '',
                                oper: oper, vlans: vlans)
          end
          if property[/vlan_mapping/]
            result = config_set('DEPRECATED',
                                PVLAN_PROPERTY[property],
                                name: @name, state: state,
                                vlans: vlans)
          end
          cli_error_check(result)
        end
      end
    end

    def configure_private_vlan_trunk_property(property, should_list_new,
                                              is_list, pr_vlan)
      case property
      when :trunk_assoc
        is_list.each do |vlans|
          vlans = vlans.split(' ')
          if vlans[0].eql? should_list_new[0]
            config_set('DEPRECATED',
                       'switchport_private_vlan_association_trunk',
                       name: @name, state: 'no',
                       vlan_pr: pr_vlan, vlan: vlans[1])
            break
          else
            next
          end
        end
        result = config_set('DEPRECATED', PVLAN_PROPERTY[property], name: @name,
                            state: '', vlan_pr: should_list_new[0],
                            vlan: should_list_new[1])
      when :mapping_trunk
        @match_found = false
        is_list.each do |vlans|
          vlans = vlans.split(' ')
          interf_vlan_list_delta(:mapping_trunk, vlans,
                                 should_list_new)
          if @match_found
            break
          else
            next
          end
        end
        result = config_set('DEPRECATED', PVLAN_PROPERTY[property], name: @name,
                            state: '', vlan_pr: should_list_new[0],
                            vlans: should_list_new[1])
      end
      cli_error_check(result)
    end

    # --------------------------
    # interf_vlan_list_delta is a helper function for the private_vlan_mapping
    # property. It walks the delta hash and adds/removes each target private
    # vlan.

    def interf_vlan_list_delta(property, is_list, should_list)
      pr_vlan = should_list[0]
      if is_list[0].eql? should_list[0]
        should_list = should_list[1].split(',')
        is_list = is_list[1].split(',')

        should_list_new = prepare_array(should_list)
        is_list_new = prepare_array(is_list)
        configure_private_vlan_host_property(property, should_list_new,
                                             is_list_new, pr_vlan)
      else
        case property
        when :mapping_trunk
          return
        end
        # If primary vlan are different we can simply replacing the all
        # config
        if should_list == default_switchport_mode_private_vlan_host_promisc
          result = config_set('DEPRECATED',
                              'switchport_mode_private_vlan_host_promiscous',
                              name: @name, state: 'no',
                              vlan_pr: '', vlans: '')

        else
          result = config_set('DEPRECATED',
                              'switchport_mode_private_vlan_host_promiscous',
                              name: @name, state: '',
                              vlan_pr: pr_vlan, vlans: should_list[1])

        end
        cli_error_check(result)
      end
    end

    def switchport_mode_private_vlan_host_promisc
      result = config_get('DEPRECATED',
                          'switchport_mode_private_vlan_host_promiscous',
                          name: @name)
      unless result == default_switchport_mode_private_vlan_host_promisc
        result = result[0].split(' ')
      end
      result
    end

    def switchport_mode_private_vlan_host_promisc=(vlans)
      deprecation_warning(__method__, 'switchport_pvlan_promiscuous')
      fail TypeError unless vlans.is_a?(Array)
      fail TypeError unless vlans.empty? || vlans.length == 2
      switchport_enable unless switchport
      Feature.private_vlan_enable
      is_list = switchport_mode_private_vlan_host_promisc
      interf_vlan_list_delta(:host_promisc, is_list, vlans)
    end

    def default_switchport_mode_private_vlan_host_promisc
      config_get_default('DEPRECATED',
                         'switchport_mode_private_vlan_host_promiscous')
    end

    def switchport_mode_private_vlan_trunk_promiscuous
      config_get('DEPRECATED',
                 'switchport_mode_private_vlan_trunk_promiscuous',
                 name: @name)
    rescue IndexError
      # Assume this is an interface that doesn't support switchport.
      # Do not raise exception since the providers will prefetch this property
      # regardless of interface type.
      # TODO: this should probably be nil instead
      return default_switchport_mode_private_vlan_trunk_promiscuous
    end

    def switchport_mode_private_vlan_trunk_promiscuous=(state)
      deprecation_warning(__method__, 'switchport_pvlan_trunk_promiscuous')
      Feature.private_vlan_enable
      switchport_enable unless switchport
      if state == default_switchport_mode_private_vlan_trunk_promiscuous
        config_set('DEPRECATED',
                   'switchport_mode_private_vlan_trunk_promiscuous',
                   name: @name, state: 'no')
      else
        config_set('DEPRECATED',
                   'switchport_mode_private_vlan_trunk_promiscuous',
                   name: @name, state: '')
      end
    end

    def default_switchport_mode_private_vlan_trunk_promiscuous
      config_get_default('DEPRECATED',
                         'switchport_mode_private_vlan_trunk_promiscuous')
    end

    def switchport_mode_private_vlan_trunk_secondary
      config_get('DEPRECATED',
                 'switchport_mode_private_vlan_trunk_secondary',
                 name: @name)
    rescue IndexError
      # Assume this is an interface that doesn't support switchport.
      # Do not raise exception since the providers will prefetch this property
      # regardless of interface type.
      # TODO: this should probably be nil instead
      return default_switchport_mode_private_vlan_trunk_secondary
    end

    def switchport_mode_private_vlan_trunk_secondary=(state)
      deprecation_warning(__method__, 'switchport_pvlan_trunk_secondary')
      Feature.private_vlan_enable
      switchport_enable unless switchport
      if state == default_switchport_mode_private_vlan_trunk_secondary
        config_set('DEPRECATED', 'switchport_mode_private_vlan_trunk_secondary',
                   name: @name, state: 'no')
      else
        config_set('DEPRECATED', 'switchport_mode_private_vlan_trunk_secondary',
                   name: @name, state: '')
      end
    end

    def default_switchport_mode_private_vlan_trunk_secondary
      config_get_default('DEPRECATED',
                         'switchport_mode_private_vlan_trunk_secondary')
    end

    def switchport_private_vlan_trunk_allowed_vlan
      result = config_get('DEPRECATED',
                          'switchport_private_vlan_trunk_allowed_vlan',
                          name: @name)

      unless result == default_switchport_private_vlan_trunk_allowed_vlan
        if result[0].eql? 'none'
          result = default_switchport_private_vlan_trunk_allowed_vlan
        else
          result = result[0].split(',')
        end
      end
      result
    end

    def switchport_private_vlan_trunk_allowed_vlan=(vlans)
      deprecation_warning(__method__, 'switchport_pvlan_trunk_allowed_vlan')
      fail TypeError unless vlans.is_a?(Array)
      Feature.private_vlan_enable
      switchport_enable unless switchport
      if vlans == default_switchport_private_vlan_trunk_allowed_vlan
        vlans = prepare_array(switchport_private_vlan_trunk_allowed_vlan)
        # If there are no vlan presently configured, we can simply return
        return if vlans == default_switchport_private_vlan_trunk_allowed_vlan
        configure_private_vlan_host_property(:allow_vlan, [],
                                             vlans, '')
      else
        vlans = prepare_array(vlans)
        is_list = prepare_array(switchport_private_vlan_trunk_allowed_vlan)
        configure_private_vlan_host_property(:allow_vlan, vlans,
                                             is_list, '')
      end
    end

    def default_switchport_private_vlan_trunk_allowed_vlan
      config_get_default('DEPRECATED',
                         'switchport_private_vlan_trunk_allowed_vlan')
    end

    def switchport_private_vlan_trunk_native_vlan
      config_get('DEPRECATED',
                 'switchport_private_vlan_trunk_native_vlan',
                 name: @name)
    end

    def switchport_private_vlan_trunk_native_vlan=(vlan)
      deprecation_warning(__method__, 'switchport_pvlan_trunk_native_vlan')
      Feature.private_vlan_enable
      switchport_enable unless switchport
      if vlan == default_switchport_private_vlan_trunk_native_vlan
        config_set('DEPRECATED',
                   'switchport_private_vlan_trunk_native_vlan',
                   name: @name, state: 'no', vlan: '')

      else
        config_set('DEPRECATED',
                   'switchport_private_vlan_trunk_native_vlan',
                   name: @name, state: '', vlan: vlan)
      end
    end

    def default_switchport_private_vlan_trunk_native_vlan
      config_get_default('DEPRECATED',
                         'switchport_private_vlan_trunk_native_vlan')
    end

    def switchport_private_vlan_association_trunk
      config_get('DEPRECATED',
                 'switchport_private_vlan_association_trunk',
                 name: @name)
    end

    def switchport_private_vlan_association_trunk=(vlans)
      deprecation_warning(__method__, 'switchport_pvlan_trunk_association')
      fail TypeError unless vlans.is_a?(Array) || vlans.empty?
      Feature.private_vlan_enable
      switchport_enable unless switchport
      if vlans == default_switchport_private_vlan_association_trunk
        config_set('DEPRECATED', 'switchport_private_vlan_association_trunk',
                   name: @name, state: 'no',
                   vlan_pr: '', vlan: '')
      else
        is_list = switchport_private_vlan_association_trunk
        configure_private_vlan_trunk_property(:trunk_assoc, vlans,
                                              is_list, vlans[0])
      end
    end

    def default_switchport_private_vlan_association_trunk
      config_get_default('DEPRECATED',
                         'switchport_private_vlan_association_trunk')
    end

    def switchport_private_vlan_mapping_trunk
      config_get('DEPRECATED',
                 'switchport_private_vlan_mapping_trunk',
                 name: @name)
    end

    def switchport_private_vlan_mapping_trunk=(vlans)
      deprecation_warning(__method__, 'switchport_pvlan_mapping_trunk')
      fail TypeError unless vlans.is_a?(Array) || vlans.empty?
      Feature.private_vlan_enable
      switchport_enable unless switchport
      if vlans == default_switchport_private_vlan_mapping_trunk
        config_set('DEPRECATED', 'switchport_private_vlan_mapping_trunk',
                   name: @name, state: 'no',
                   vlan_pr: '', vlans: '')
      else
        is_list = switchport_private_vlan_mapping_trunk
        configure_private_vlan_trunk_property(:mapping_trunk, vlans,
                                              is_list, vlans[0])
      end
    end

    def default_switchport_private_vlan_mapping_trunk
      config_get_default('DEPRECATED',
                         'switchport_private_vlan_mapping_trunk')
    end

    def private_vlan_mapping
      match = config_get('DEPRECATED',
                         'private_vlan_mapping',
                         name: @name)
      match[0].delete!(' ') unless match == default_private_vlan_mapping
      match
    end

    def private_vlan_mapping=(vlans)
      deprecation_warning(__method__, 'pvlan_mapping')
      fail TypeError unless vlans.is_a?(Array) || vlans.empty?
      Feature.private_vlan_enable
      feature_vlan_set(true)
      if vlans == default_private_vlan_mapping
        config_set('DEPRECATED', 'private_vlan_mapping',
                   name: @name, state: 'no', vlans: '')
      else
        is_list = private_vlan_mapping
        new_is_list = prepare_array(is_list)
        new_vlans = prepare_array(vlans)
        configure_private_vlan_host_property(:vlan_mapping, new_vlans,
                                             new_is_list, '')
      end
    end

    def default_private_vlan_mapping
      config_get_default('DEPRECATED',
                         'private_vlan_mapping')
    end
  end  # Class
end    # Module
