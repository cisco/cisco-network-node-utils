# December 2015, Sai Chintalapudi
#
# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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
  # node_utils class for portchannel_global
  class PortChannelGlobal < NodeUtil
    attr_reader :name

    def initialize(name)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name == 'default'
      @name = name.downcase
    end

    def self.globals
      { 'default' => PortChannelGlobal.new('default') }
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def hash_distribution
      config_get('portchannel_global', 'hash_distribution')
    end

    def hash_distribution=(val)
      config_set('portchannel_global',
                 'hash_distribution', val)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_hash_distribution
      config_get_default('portchannel_global', 'hash_distribution')
    end

    def load_defer
      config_get('portchannel_global', 'load_defer')
    end

    def load_defer=(val)
      config_set('portchannel_global', 'load_defer', val)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_load_defer
      config_get_default('portchannel_global', 'load_defer')
    end

    def resilient
      config_get('portchannel_global', 'resilient')
    end

    def resilient=(state)
      fail TypeError unless state == true || state == false
      no_cmd = (state ? '' : 'no')
      config_set('portchannel_global', 'resilient', no_cmd)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_resilient
      config_get_default('portchannel_global', 'resilient')
    end

    # port-channel load-balance is a complicated command
    # and this has so many forms in the same device and in
    # different devices.
    # For ex:
    # port-channel load-balance src-dst ip rotate 4 concatenation symmetric
    # port-channel load-balance resilient
    # port-channel load-balance ethernet destination-mac CRC10c
    # port-channel load-balance ethernet source-ip
    # port-channel load-balance dst ip-l4port rotate 4 asymmetric
    # port-channel load-balance dst ip-l4port-vlan module 9
    # port-channel load-balance hash-modulo
    # we need to eliminate all the clutter and get the correct
    # line of config first and after that get index of each property
    # and get the property value because some properties may or
    # may not be present always.
    # This method returns a hash
    def port_channel_load_balance
      lb = config_get('portchannel_global',
                      'port_channel_load_balance')
      hash = {}
      lb.each do |line|
        next if line[/(internal|resilient|module|fex|hash)/]
        params = line.split
        lb_type = config_get('portchannel_global', 'load_balance_type')
        case lb_type.to_sym
        when :ethernet # n6k
          _parse_ethernet_params(hash, params)
        when :asymmetric # n7k
          _parse_asymmetric_params(hash, params, line)
        when :symmetry # n9k
          _parse_symmetry_params(hash, params, line)
        end
      end
      hash
    end

    def asymmetric
      port_channel_load_balance[:asymmetric]
    end

    def default_asymmetric
      config_get_default('portchannel_global',
                         'asymmetric')
    end

    def bundle_hash
      port_channel_load_balance[:bundle_hash]
    end

    def default_bundle_hash
      config_get_default('portchannel_global',
                         'bundle_hash')
    end

    def bundle_select
      port_channel_load_balance[:bundle_select]
    end

    def default_bundle_select
      config_get_default('portchannel_global',
                         'bundle_select')
    end

    def concatenation
      port_channel_load_balance[:concatenation]
    end

    def default_concatenation
      config_get_default('portchannel_global',
                         'concatenation')
    end

    def hash_poly
      port_channel_load_balance[:hash_poly]
    end

    def default_hash_poly
      config_get_default('portchannel_global',
                         'hash_poly')
    end

    def rotate
      port_channel_load_balance[:rotate]
    end

    def default_rotate
      config_get_default('portchannel_global',
                         'rotate')
    end

    def symmetry
      port_channel_load_balance[:symmetry]
    end

    def default_symmetry
      config_get_default('portchannel_global',
                         'symmetry')
    end

    def port_channel_load_balance=(bselect, bhash, hpoly, asy, sy, conc, rot)
      lb_type = config_get('portchannel_global', 'load_balance_type')
      case lb_type.to_sym
      when :ethernet # n6k
        if bselect == 'src'
          sel = 'source'
        elsif bselect == 'dst'
          sel = 'destination'
        else
          sel = 'source-dest'
        end
        sel_hash = sel + '-' + bhash
        # port-channel load-balance ethernet destination-mac CRC10c
        config_set('portchannel_global', 'port_channel_load_balance',
                   'ethernet', sel_hash, hpoly, '', '', '')
      when :asymmetric # n7k
        asym = (asy == true) ? 'asymmetric' : ''
        # port-channel load-balance dst ip-l4port rotate 4 asymmetric
        config_set('portchannel_global', 'port_channel_load_balance',
                   bselect, bhash, 'rotate', rot.to_s, asym, '')
      when :symmetry # n9k
        sym = sy ? 'symmetric' : ''
        concat = conc ? 'concatenation' : ''
        rot_str = rot.zero? ? '' : 'rotate'
        rot_val = rot.zero? ? '' : rot.to_s
        # port-channel load-balance src-dst ip rotate 4 concatenation symmetric
        config_set('portchannel_global', 'port_channel_load_balance',
                   bselect, bhash, rot_str, rot_val, concat, sym)
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    # on n6k, the bundle hash and bundle select are
    # merged into one and so we need to break them apart,
    # also they are called source and destination instead of
    # src and dst as in other devices, so we convert them
    def _parse_ethernet_params(hash, params)
      hash_poly = params[2]
      # hash_poly is not shown on the running config
      # if it is default under some circumstatnces
      hash_poly = hash_poly.nil? ? 'CRC10b' : hash_poly
      select_hash = params[1]
      lparams = select_hash.split('-')
      if lparams[0].downcase == 'destination'
        bselect = 'dst'
        bhash = lparams[1]
      else
        if select_hash.include? '-dest-'
          bselect = 'src-dst'
          bhash = lparams[2]
          # there are bundles hashes like ip-only and
          # port-only specific to src-dst
          bhash += '-only' if select_hash.include? 'only'
        else
          bselect = 'src'
          bhash = lparams[1]
        end
      end
      hash[:bundle_select] = bselect
      hash[:bundle_hash] = bhash
      hash[:hash_poly] = hash_poly
      hash
    end

    def _parse_asymmetric_params(hash, params, line)
      bselect = params[0]
      bhash = params[1]
      # asymmetric keyword does not show up if it is false
      asym = (line.include? 'asymmetric') ? true : false
      ri = params.index('rotate')
      rotate = params[ri + 1].to_i
      hash[:bundle_select] = bselect
      hash[:bundle_hash] = bhash
      hash[:asymmetric] = asym
      hash[:rotate] = rotate
      hash
    end

    def _parse_symmetry_params(hash, params, line)
      bselect = params[0]
      bhash = params[1]
      ri = params.index('rotate')
      rotate = params[ri + 1].to_i
      # concatenation and symmetry keywords do not show up if false
      concat = (line.include? 'concatenation') ? true : false
      sym = (line.include? 'symmetric') ? true : false
      hash[:bundle_select] = bselect
      hash[:bundle_hash] = bhash
      hash[:symmetry] = sym
      hash[:rotate] = rotate
      hash[:concatenation] = concat
      hash
    end
  end # class
end # module
