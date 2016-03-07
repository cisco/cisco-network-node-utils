# NXAPI implementation of BridgeDomain class
#
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

module Cisco
  # node_utils class for bridge_domain
  class BridgeDomain < NodeUtil
    attr_reader :bd_ids

    def initialize(bds, instantiate=true)
      # Spaces are removed as bridge-domain cli doesn't accept value with
      # space
      @bd_ids = bds.to_s.gsub(/\s+/, '')
      fail 'bridge-domain value is empty' if @bd_ids.empty? # no empty strings

      create if instantiate
    end

    def to_s
      "Bridge Domain #{bd_ids}"
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
        left = bd_list.first
        right = nil
        farray.each do |aelem|
          if right && aelem != right.succ
            if left == right
              lranges << left
            else
              lranges << Range.new(left, right)
            end
            left = aelem
          end
          right = aelem
        end
        if left == right
          lranges << left
        else
          lranges << Range.new(left, right)
        end
      end
      lranges.to_s.gsub('..', '-').delete('[').delete(']').delete(' ')
    end

    def self.bds
      hash = {}
      bd_list = config_get('bridge_domain', 'all_bds')
      return hash if bd_list.nil?

      final_bd_list =
          bd_list.map { |elem| BridgeDomain.bd_ids_to_array(elem) }
          .flatten.uniq.sort
      final_bd_list.each do |id|
        hash[id] = BridgeDomain.new(id, false)
      end
      hash
    end

    # This function will first add bds to the system bridge-domain and then
    # create the bds. If bds already existing then just create. Else add the
    # non added bds to system range first then create all. This is to avoid the
    # idempotency issue as system add command throws error if a bd is already
    # present in the system range.
    def create
      sys_bds_array = BridgeDomain.bd_ids_to_array(system_bd_add)
      inp_bds_array = BridgeDomain.bd_ids_to_array(@bd_ids)
      if (inp_bds_array - sys_bds_array).any?
        add_bds = BridgeDomain.bd_list_to_string(inp_bds_array - sys_bds_array)
        config_set('bridge_domain', 'system_bd_add', addbd: add_bds)
      end
      config_set('bridge_domain', 'create', crbd: @bd_ids)
    end

    def destroy
      config_set('bridge_domain', 'destroy', delbd: @bd_ids, rembd: @bd_ids)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    # Bridge-Domain type change to fabric-control
    # bridge-domain 100
    #   fabric-control
    # This type property can be defined only for one bd
    def fabric_control
      config_get('bridge_domain', 'fabric_control')
    end

    def fabric_control=(val)
      state = (val) ? '' : 'no'
      config_set('bridge_domain', 'fabric_control', bd: @bd_ids, state: state)
    end

    def default_fabric_control
      config_get_default('bridge_domain', 'fabric_control')
    end

    # Bridge-Domain member vni assigning case
    # Not all the bds created or initialized in this class context can have the
    # member vni's mapped. So will get the vnis of the ones which are mapped to
    # the bds.
    # Eg: Suppose the bd mapping is as below on the switch
    # bridge-domain 100,105,107-109,150
    #   member vni 5000, 8000, 5007-5008, 7000, 5050
    # If puppet layer tries to get values of 100-107 bds the final_bd_vni map
    # which is returned will contain only these mappings as
    # {100=>5000,101=>0,102=>0,103>0,104=>0,105=>8000,106=>0,107=>5007}
    def member_vni
      final_bd_vni = {}
      curr_vni = config_get('bridge_domain', 'member_vni')
      curr_bd_vni = config_get('bridge_domain', 'member_vni_bd')
      return final_bd_vni if curr_vni.empty? || curr_bd_vni.empty?

      curr_vni_list = BridgeDomain.bd_ids_to_array(curr_vni)
      curr_bd_vni_list = BridgeDomain.bd_ids_to_array(curr_bd_vni)
      input_bds = BridgeDomain.bd_ids_to_array(@bd_ids)

      hash_map = Hash[curr_bd_vni_list.zip(curr_vni_list.map)]
      input_bds.each do |bd|
        final_bd_vni[bd.to_i] =
            hash_map.key?(bd.to_i) ? hash_map[bd.to_i] : 0
      end
      final_bd_vni
    end

    # This member_vni mapping will be executed only when the val is not empty
    # else it will be treated as a 'no' cli and executed as required.
    # If the mappings do not match in any fashion then cli normally returns a
    # failure which will be handled.
    def member_vni=(val)
      val = val.to_s
      Feature.vni_enable
      if val.empty?
        bd_val = member_vni.keys.join(',')
        vni_val = member_vni.values.join(',')
        return '' if vni_val.empty?
        config_set('bridge_domain', 'member_vni', vnistate: 'no', vni: vni_val,
                   bd: bd_val, membstate: 'no', membvni: vni_val)
      else
        config_set('bridge_domain', 'member_vni', vnistate: '', vni: val.to_s,
                   bd: @bd_ids, membstate: '', membvni: val.to_s)
      end
    end

    def default_member_vni
      config_get_default('bridge_domain', 'member_vni')
    end

    # Bridge-Domain name assigning case
    # bridge-domain 100
    #   name PepsiCo
    def name
      config_get('bridge_domain', 'name', bd: @bd_ids)
    end

    def name=(str)
      fail TypeError unless str.is_a?(String)
      if str.empty?
        config_set('bridge_domain', 'name', bd: @bd_ids, state: 'no', name: '')
      else
        config_set('bridge_domain', 'name', bd: @bd_ids, state: '', name: str)
      end
    end

    def default_name
      sprintf('Bridge-Domain%s', @bd_ids)
    end

    # Bridge-Domain Shutdown case
    # bridge-domain 100
    #   shutdown
    def shutdown
      result = config_get('bridge_domain', 'shutdown', bd: @bd_ids)
      # Valid result is either: "active"(aka no shutdown) or "shutdown"
      result[/DOWN/] ? true : false
    end

    def shutdown=(val)
      state = (val) ? '' : 'no'
      config_set('bridge_domain', 'shutdown', bd: @bd_ids, state: state)
    end

    def default_shutdown
      config_get_default('bridge_domain', 'shutdown')
    end

    # getter for system bridge-domain
    def system_bd_add
      config_get('bridge_domain', 'system_bd_add')
    end
  end  # Class
end    # Module
