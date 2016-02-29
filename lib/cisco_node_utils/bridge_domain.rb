# February 2016, Rohan Gandhi Korlepara
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
require_relative 'feature'
require_relative 'vdc'

module Cisco
  # node_utils class for bridge_domain
  class BridgeDomain < NodeUtil
    attr_reader :name, :bd_ids

    def initialize(bds, instantiate=true)
      @bd_ids = bds.to_s
      fail 'bridge-domain value is empty' if @bd_ids.empty? # no empty strings
      fail 'bridge-domain value has spaces' if @bd_ids.include?(' ') # no spaces

      # Check if the given input bd_ids does contain only numeric value or range
      # of numeric values
      # Also bd_ids need to fall in range of 2-2967
      narray = @bd_ids.split(',')
      narray.each do |elem|
        if elem.include?('-')
          earray = elem.split('-')
          earray.each do |temp_elem|
            fail 'bridge-domain cannot be a string' unless
                                    BridgeDomain.number?(temp_elem)
            fail 'Invalid bridge-domain value' unless
                                    temp_elem.to_i > 1 && temp_elem.to_i < 3968
          end
        else
          fail 'bridge-domain cannot be a string' unless
                                    BridgeDomain.number?(elem)
          fail 'Invalid bridge-domain value' unless
                                    elem.to_i > 1 && elem.to_i < 3968
        end
      end

      create if instantiate
    end

    def self.number?(string)
      true if Integer(string)
    rescue
      false
    end

    # This will expand the string to a list of bds as integers
    def self.bd_ids_to_array(bdid_string)
      list = []
      narray = bdid_string.split(',')
      narray.each do |elem|
        if elem.include?('-')
          es = elem.gsub('-', '..')
          ea = es.split('..').map { |d| Integer(d) }
          er = ea[0]..ea[1]
          list << er.to_a
        else
          list << elem.to_i
        end
      end
      list.flatten
    end

    # This method will generate a batched string if a list is passed as
    # argument
    # Input would be as [1,2,3,4,5,10,11,12,7,30,100,31,32]
    # output will be 1-5,10-12,7,30,100,31-32
    def self.bd_list_to_string(bd_list)
      farray = bd_list.compact
      lranges = []
      unless farray.empty?
        left = array.first
        right = nil
        farray.each do |aelem|
          if right && aelem != r.succ
            if left == right
              lranges << left
            else
              lranges << Range.new(left, right)
            end
            left = aelem
          end
          right = aelem
        end
        lranges << Range.new(left, right)
      end
      lranges.to_s.gsub('..', '-').delete('[').delete(']').delete(' ')
    end

    def cli_error_check(result)
      # The NXOS bridge-domain cli does not raise an exception in some
      # conditions and instead just displays a STDOUT error message;
      # thus NXAPI does not detect the failure and we must catch it by
      # inspecting the "body" hash entry returned by NXAPI. This
      # bridge-domain cli behavior is unlikely to change.
      fail result[2]['body'] if
        result[2].is_a?(Hash) &&
        /(ERROR:|Warning:)/.match(result[2]['body'].to_s)

      # Some test environments get result[2] as a string instead of a hash
      fail result[2] if
        result[2].is_a?(String) &&
        /(ERROR:|Warning:)/.match(result[2])
    end

    def create
      result = config_set('bridge_domain', 'create', @bd_ids, @bd_ids)
      cli_error_check(result)
    rescue CliError => e
      raise "[bridge-domain #{@bd_ids}] '#{e.command}' : #{e.clierror}"
    end

    def destroy
      result = config_set('bridge_domain', 'destroy', @bd_ids, @bd_ids)
      cli_error_check(result)
    rescue CliError => e
      raise "[bridge-domain #{@bd_ids}] '#{e.command}' : #{e.clierror}"
    end

    def self.allbds
      hash = {}
      bd_list = config_get('bridge_domain', 'all_bds')
      return hash if bd_list.nil?

      bd_list.each do |id|
        hash[id] = BridgeDomain.new(id, false)
      end
      hash
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    # Bridge-Domain Shutdown case
    def shutdown
      result = config_get('bridge_domain', 'shutdown', @bd_ids)
      # Valid result is either: "active"(aka no shutdown) or "shutdown"
      result[/DOWN/] ? true : false
    end

    def shutdown=(val)
      no_cmd = (val) ? '' : 'no'
      result = config_set('bridge_domain', 'shutdown', @bd_ids, no_cmd)
      cli_error_check(result)
    rescue CliError => e
      raise "[bridge-domain #{@bd_ids}] '#{e.command}' : #{e.clierror}"
    end

    def default_shutdown
      config_get_default('bridge_domain', 'shutdown')
    end

    # Bridge-Domain name assigning case
    def name
      config_get('bridge_domain', 'name', @bd_ids)
    end

    def name=(str)
      fail TypeError unless str.is_a?(String)
      if str.empty?
        result = config_set('bridge_domain', 'name', @bd_ids, 'no', '')
      else
        result = config_set('bridge_domain', 'name', @bd_ids, '', str)
      end
      cli_error_check(result)
    rescue CliError => e
      raise "[bridge-domain #{@bd_ids}] '#{e.command}' : #{e.clierror}"
    end

    def default_name
      sprintf('Bridge-Domain%s', @bd_ids)
    end

    # Bridge-Domain type change to fabric-control
    def fabric_control
      config_get('bridge_domain', 'fabric_control')
    end

    def fabric_control=(val)
      no_cmd = (val) ? '' : 'no'
      result = config_set('bridge_domain', 'fabric_control', @bd_ids, no_cmd)
      cli_error_check(result)
    rescue CliError => e
      raise "[bridge-domain #{@bd_ids}] '#{e.command}' : #{e.clierror}"
    end

    def default_fabric_control
      config_get_default('bridge_domain', 'fabric_control')
    end

    # Bridge-Domain member vni assigning case
    def member_vni
      vni_list = []
      curr_vni = config_get('bridge_domain', 'member_vni')
      curr_bd_vni = config_get('bridge_domain', 'member_vni_bd')
      return '' if curr_vni.empty? || curr_bd_vni.empty?

      curr_vni_list = Bridge_Domain.bd_ids_to_array(curr_vni)
      curr_bd_vni_list = Bridge_Domain.bd_ids_to_array(curr_bd_vni)
      input_bds = Bridge_Domain.bd_ids_to_array(@bd_ids)

      hash_map = Hash[curr_bd_vni_list.zip(curr_vni_list.map)]
      input_bds.each do |bd|
        vni_list << hash_map[bd]
      end
      return '' unless vni_list.any?

      Bridge_domain.bd_list_to_string(vni_list)
    end

    def set_member_vni=(cmd, val)
      no_cmd = (cmd) ? '' : 'no'
      vdc = Vdc.new('default')
      vdc.limit_resource_module_type = 'f3' unless
        vdc.limit_resource_module_type == 'f3'
      Feature.vni_enable unless Feature.vni_enabled?
      result = config_set('bridge_domain', 'member_vni', no_cmd, val, @bd_ids,
                          no_cmd, val)
      cli_error_check(result)
    rescue CliError => e
      raise "[bridge-domain #{@bd_ids}] '#{e.command}' : #{e.clierror}"
    end

    def default_member_vni
      config_get_default('bridge_domain', 'member_vni')
    end
  end  # Class
end    # Module
