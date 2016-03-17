# NXAPI implementation of BridgeDomainVNI class
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
  # node_utils class for bridge_domain_vni
  class BridgeDomainVNI < NodeUtil
    attr_reader :bd_ids, :bd_ids_list

    def initialize(bds, instantiate=true)
      # Spaces are removed as bridge-domain cli doesn't accept value with
      # space
      @bd_ids = bds.to_s.gsub(/\s+/, '')
      fail 'bridge-domain value is empty' if @bd_ids.empty? # no empty strings

      @bd_ids_list = Utils.string_to_array(@bd_ids)
      create if instantiate
    end

    def to_s
      "Bridge Domain #{bd_ids}"
    end

    def self.rangebds
      hash = {}
      bd_list = config_get('bridge_domain_vni', 'range_bds')
      return hash if bd_list.nil?

      bd_list.each do |id|
        hash[id] = BridgeDomainVNI.new(id, false)
      end
      hash
    end

    def curr_bd_vni_hash
      final_bd_vni = {}
      curr_vni = config_get('bridge_domain_vni', 'member_vni')
      curr_bd_vni = config_get('bridge_domain_vni', 'member_vni_bd')
      return final_bd_vni if curr_vni.empty? || curr_bd_vni.empty?

      curr_vni_list = Utils.string_to_array(curr_vni)
      curr_bd_vni_list = Utils.string_to_array(curr_bd_vni)

      hash_map = Hash[curr_bd_vni_list.zip(curr_vni_list.map)]
      @bd_ids_list.each do |bd|
        final_bd_vni[bd.to_i] = hash_map[bd.to_i] if hash_map.key?(bd.to_i)
      end
      final_bd_vni
    end

    # This function will first add bds to the system bridge-domain and then
    # create the bds. If bds already existing then just create. Else add the
    # non added bds to system range first then create all. This is to avoid the
    # idempotency issue as system add command throws error if a bd is already
    # present in the system range.
    def create
      sys_bds_array = Utils.string_to_array(system_bd_add)
      if (@bd_ids_list - sys_bds_array).any?
        add_bds = Utils
                  .unsorted_list_to_string(@bd_ids_list - sys_bds_array)
        config_set('bridge_domain_vni', 'system_bd_add', addbd: add_bds)
      end
      config_set('bridge_domain_vni', 'create', crbd: @bd_ids)
    end

    def destroy
      bd_vni = curr_bd_vni_hash
      bd_val = bd_vni.keys.join(',')
      vni_val = bd_vni.values.join(',')
      return '' if vni_val.empty?
      config_set('bridge_domain_vni', 'member_vni', vnistate: 'no',
                 vni: vni_val, bd: bd_val, membstate: 'no', membvni: vni_val)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    # Bridge-Domain member vni assigning case
    # Not all the bds created or initialized in this class context can have the
    # member vni's mapped. So will get the vnis of the ones which are mapped to
    # the bds.
    # Eg: Suppose the bd mapping is as below on the switch
    # bridge-domain 100,105,107-109,150
    #   member vni 5000, 8000, 5007-5008, 7000, 5050
    # If puppet layer tries to get values of 100,105,107 bds as defined in
    # manifest then the final_bd_vni map which is returned will contain only
    # these mappings as below;
    # '5000,8000,5007'
    # This is also to handle the idempotence case, and if any mismatch then set
    # the member_vni
    def member_vni
      bd_vni_hash = curr_bd_vni_hash
      ret_list = []
      @bd_ids_list.each do |bd|
        ret_list << bd_vni_hash[bd]
      end
      Utils.unsorted_list_to_string(ret_list)
    end

    # This member_vni mapping will be executed only when the val is not empty
    # else it will be treated as a 'no' cli and executed as required.
    # If the mappings do not match in any fashion then cli normally returns a
    # failure which will be handled.
    # During set of member vni we first see if any bd is mapped to some other
    # vni, if yes then remove that one and apply the new vni.
    # Eg: bridge-domain 100-110
    #       member vni 5100-5110
    # Now the manifest is changed to 5100-5105,6106-6110, so hence first
    # 5106-5110 mapping is removed and then 6106-6110 is applied.
    def member_vni=(val)
      val = val.to_s
      Feature.vni_enable
      bd_vni = curr_bd_vni_hash
      if val.empty?
        bd_val = bd_vni.keys.join(',')
        vni_val = bd_vni.values.join(',')
        return '' if vni_val.empty?
        config_set('bridge_domain_vni', 'member_vni', vnistate: 'no',
                   vni: vni_val, bd: bd_val, membstate: 'no', membvni: vni_val)
      else
        unless bd_vni.empty?
          inp_vni_list = Utils.string_to_array(val.to_s)
          inp_bd_vni_hash = Hash[@bd_ids_list.zip(inp_vni_list)]

          temp_hash = bd_vni.to_a.keep_if { |k, _v| inp_bd_vni_hash.key? k }
          rem_hash = (temp_hash.to_a - inp_bd_vni_hash.to_a).to_h

          rm_bd = rem_hash.keys.join(',')
          rm_vni = rem_hash.values.join(',')
          config_set('bridge_domain_vni', 'member_vni', vnistate: 'no',
                     vni: rm_vni, bd: rm_bd, membstate: 'no', membvni: rm_vni)
        end
        config_set('bridge_domain_vni', 'member_vni', vnistate: '', vni: val,
                   bd: @bd_ids, membstate: '', membvni: val)
      end
    end

    def default_member_vni
      config_get_default('bridge_domain_vni', 'member_vni')
    end

    # getter for system bridge-domain
    def system_bd_add
      config_get('bridge_domain_vni', 'system_bd_add')
    end
  end  # Class
end    # Module