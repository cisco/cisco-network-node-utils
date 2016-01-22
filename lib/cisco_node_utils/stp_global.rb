# January 2016, Sai Chintalapudi
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
  # node_utils class for stp_global
  class StpGlobal < NodeUtil
    attr_reader :name

    def initialize(name)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name == 'default'
      @name = name.downcase
    end

    def self.globals
      { 'default' => StpGlobal.new('default') }
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def bd_designated_priority
      config_get('stp_global', 'bd_designated_priority')
    end

    def bd_designated_priority=(list)
      config_set('stp_global', 'bd_designated_priority',
                 'no', '2-3967', '')
      list.each do |range, pri|
        config_set('stp_global', 'bd_designated_priority',
                   '', range, pri)
      end
    end

    def default_bd_designated_priority
      config_get_default('stp_global', 'bd_designated_priority')
    end

    def bd_forward_time
      config_get('stp_global', 'bd_forward_time')
    end

    def bd_forward_time=(list)
      config_set('stp_global', 'bd_forward_time',
                 'no', '2-3967', '')
      list.each do |range, ft|
        config_set('stp_global', 'bd_forward_time',
                   '', range, ft)
      end
    end

    def default_bd_forward_time
      config_get_default('stp_global', 'bd_forward_time')
    end

    def bd_hello_time
      config_get('stp_global', 'bd_hello_time')
    end

    def bd_hello_time=(list)
      config_set('stp_global', 'bd_hello_time',
                 'no', '2-3967', '')
      list.each do |range, ht|
        config_set('stp_global', 'bd_hello_time',
                   '', range, ht)
      end
    end

    def default_bd_hello_time
      config_get_default('stp_global', 'bd_hello_time')
    end

    def bd_max_age
      config_get('stp_global', 'bd_max_age')
    end

    def bd_max_age=(list)
      config_set('stp_global', 'bd_max_age',
                 'no', '2-3967', '')
      list.each do |range, ma|
        config_set('stp_global', 'bd_max_age',
                   '', range, ma)
      end
    end

    def default_bd_max_age
      config_get_default('stp_global', 'bd_max_age')
    end

    def bd_priority
      config_get('stp_global', 'bd_priority')
    end

    def bd_priority=(list)
      config_set('stp_global', 'bd_priority',
                 'no', '2-3967', '')
      list.each do |range, pri|
        config_set('stp_global', 'bd_priority',
                   '', range, pri)
      end
    end

    def default_bd_priority
      config_get_default('stp_global', 'bd_priority')
    end

    def bd_root_priority
      config_get('stp_global', 'bd_root_priority')
    end

    def bd_root_priority=(list)
      config_set('stp_global', 'bd_root_priority',
                 'no', '2-3967', '')
      list.each do |range, pri|
        config_set('stp_global', 'bd_root_priority',
                   '', range, pri)
      end
    end

    def default_bd_root_priority
      config_get_default('stp_global', 'bd_root_priority')
    end

    def bpdufilter
      config_get('stp_global', 'bpdufilter')
    end

    def bpdufilter=(state)
      fail TypeError unless state == true || state == false
      no_cmd = (state ? '' : 'no')
      config_set('stp_global', 'bpdufilter', no_cmd)
    end

    def default_bpdufilter
      config_get_default('stp_global', 'bpdufilter')
    end

    def bpduguard
      config_get('stp_global', 'bpduguard')
    end

    def bpduguard=(state)
      fail TypeError unless state == true || state == false
      no_cmd = (state ? '' : 'no')
      config_set('stp_global', 'bpduguard', no_cmd)
    end

    def default_bpduguard
      config_get_default('stp_global', 'bpduguard')
    end

    def bridge_assurance
      config_get('stp_global', 'bridge_assurance')
    end

    def bridge_assurance=(state)
      fail TypeError unless state == true || state == false
      no_cmd = (state ? '' : 'no')
      config_set('stp_global', 'bridge_assurance', no_cmd)
    end

    def default_bridge_assurance
      config_get_default('stp_global', 'bridge_assurance')
    end

    def domain
      config_get('stp_global', 'domain')
    end

    def domain=(val)
      if val
        state = ''
      else
        state = 'no'
        val = '1' # dummy val to satisfy the CLI
      end
      config_set('stp_global',
                 'domain', state, val)
    end

    def default_domain
      config_get_default('stp_global', 'domain')
    end

    def fcoe
      config_get('stp_global', 'fcoe')
    end

    def fcoe=(state)
      fail TypeError unless state == true || state == false
      no_cmd = (state ? '' : 'no')
      config_set('stp_global', 'fcoe', no_cmd)
    end

    def default_fcoe
      config_get_default('stp_global', 'fcoe')
    end

    def loopguard
      config_get('stp_global', 'loopguard')
    end

    def loopguard=(state)
      fail TypeError unless state == true || state == false
      no_cmd = (state ? '' : 'no')
      config_set('stp_global', 'loopguard', no_cmd)
    end

    def default_loopguard
      config_get_default('stp_global', 'loopguard')
    end

    def mode
      config_get('stp_global', 'mode')
    end

    def mode=(val)
      if val == default_mode
        config_set('stp_global', 'mode', 'no', '')
      else
        config_set('stp_global', 'mode', '', val)
      end
    end

    def default_mode
      config_get_default('stp_global', 'mode')
    end

    def mst_designated_priority
      config_get('stp_global', 'mst_designated_priority')
    end

    def mst_designated_priority=(list)
      check_stp_mode_mst
      config_set('stp_global', 'mst_designated_priority',
                 'no', '0-4094', '')
      list.each do |range, pri|
        config_set('stp_global', 'mst_designated_priority',
                   '', range, pri)
      end
    end

    def default_mst_designated_priority
      config_get_default('stp_global', 'mst_designated_priority')
    end

    def mst_forward_time
      config_get('stp_global', 'mst_forward_time')
    end

    def mst_forward_time=(val)
      check_stp_mode_mst
      if val == default_mst_forward_time
        state = 'no'
        val = ''
      else
        state = ''
      end
      config_set('stp_global',
                 'mst_forward_time', state, val)
    end

    def default_mst_forward_time
      config_get_default('stp_global', 'mst_forward_time')
    end

    def mst_hello_time
      config_get('stp_global', 'mst_hello_time')
    end

    def mst_hello_time=(val)
      check_stp_mode_mst
      if val == default_mst_hello_time
        state = 'no'
        val = ''
      else
        state = ''
      end
      config_set('stp_global',
                 'mst_hello_time', state, val)
    end

    def default_mst_hello_time
      config_get_default('stp_global', 'mst_hello_time')
    end

    def mst_inst_vlan_map
      config_get('stp_global', 'mst_inst_vlan_map')
    end

    def mst_inst_vlan_map=(list)
      check_stp_mode_mst
      config_set('stp_global', 'mst_inst_vlan_map',
                 '0', '1-4094')
      list.each do |inst, range|
        config_set('stp_global', 'mst_inst_vlan_map',
                   inst, range)
      end
    end

    def default_mst_inst_vlan_map
      config_get_default('stp_global', 'mst_inst_vlan_map')
    end

    def mst_max_age
      config_get('stp_global', 'mst_max_age')
    end

    def mst_max_age=(val)
      check_stp_mode_mst
      if val == default_mst_max_age
        state = 'no'
        val = ''
      else
        state = ''
      end
      config_set('stp_global',
                 'mst_max_age', state, val)
    end

    def default_mst_max_age
      config_get_default('stp_global', 'mst_max_age')
    end

    def mst_max_hops
      config_get('stp_global', 'mst_max_hops')
    end

    def mst_max_hops=(val)
      check_stp_mode_mst
      if val == default_mst_max_hops
        state = 'no'
        val = ''
      else
        state = ''
      end
      config_set('stp_global',
                 'mst_max_hops', state, val)
    end

    def default_mst_max_hops
      config_get_default('stp_global', 'mst_max_hops')
    end

    def mst_name
      config_get('stp_global', 'mst_name')
    end

    def mst_name=(val)
      check_stp_mode_mst
      if val
        state = ''
      else
        state = 'no'
        val = ''
      end
      config_set('stp_global',
                 'mst_name', state, val)
    end

    def default_mst_name
      config_get_default('stp_global', 'mst_name')
    end

    def mst_priority
      config_get('stp_global', 'mst_priority')
    end

    def mst_priority=(list)
      check_stp_mode_mst
      config_set('stp_global', 'mst_priority',
                 'no', '0-4094', '')
      list.each do |range, pri|
        config_set('stp_global', 'mst_priority',
                   '', range, pri)
      end
    end

    def default_mst_priority
      config_get_default('stp_global', 'mst_priority')
    end

    def mst_revision
      config_get('stp_global', 'mst_revision')
    end

    def mst_revision=(val)
      check_stp_mode_mst
      if val.zero?
        state = 'no'
        val = ''
      else
        state = ''
      end
      config_set('stp_global',
                 'mst_revision', state, val)
    end

    def default_mst_revision
      config_get_default('stp_global', 'mst_revision')
    end

    def mst_root_priority
      config_get('stp_global', 'mst_root_priority')
    end

    def mst_root_priority=(list)
      check_stp_mode_mst
      config_set('stp_global', 'mst_root_priority',
                 'no', '0-4094', '')
      list.each do |range, pri|
        config_set('stp_global', 'mst_root_priority',
                   '', range, pri)
      end
    end

    def default_mst_root_priority
      config_get_default('stp_global', 'mst_root_priority')
    end

    def pathcost
      config_get('stp_global', 'pathcost')
    end

    def pathcost=(val)
      if val == default_pathcost
        config_set('stp_global', 'pathcost', 'no', '')
      else
        config_set('stp_global', 'pathcost', '', val)
      end
    end

    def default_pathcost
      config_get_default('stp_global', 'pathcost')
    end

    def vlan_designated_priority
      config_get('stp_global', 'vlan_designated_priority')
    end

    def vlan_designated_priority=(list)
      config_set('stp_global', 'vlan_designated_priority',
                 'no', '1-4094', '')
      list.each do |range, pri|
        config_set('stp_global', 'vlan_designated_priority',
                   '', range, pri)
      end
    end

    def default_vlan_designated_priority
      config_get_default('stp_global', 'vlan_designated_priority')
    end

    def vlan_forward_time
      config_get('stp_global', 'vlan_forward_time')
    end

    def vlan_forward_time=(list)
      config_set('stp_global', 'vlan_forward_time',
                 'no', '1-4094', '')
      list.each do |range, ft|
        config_set('stp_global', 'vlan_forward_time',
                   '', range, ft)
      end
    end

    def default_vlan_forward_time
      config_get_default('stp_global', 'vlan_forward_time')
    end

    def vlan_hello_time
      config_get('stp_global', 'vlan_hello_time')
    end

    def vlan_hello_time=(list)
      config_set('stp_global', 'vlan_hello_time',
                 'no', '1-4094', '')
      list.each do |range, ht|
        config_set('stp_global', 'vlan_hello_time',
                   '', range, ht)
      end
    end

    def default_vlan_hello_time
      config_get_default('stp_global', 'vlan_hello_time')
    end

    def vlan_max_age
      config_get('stp_global', 'vlan_max_age')
    end

    def vlan_max_age=(list)
      config_set('stp_global', 'vlan_max_age',
                 'no', '1-4094', '')
      list.each do |range, ma|
        config_set('stp_global', 'vlan_max_age',
                   '', range, ma)
      end
    end

    def default_vlan_max_age
      config_get_default('stp_global', 'vlan_max_age')
    end

    def vlan_priority
      config_get('stp_global', 'vlan_priority')
    end

    def vlan_priority=(list)
      config_set('stp_global', 'vlan_priority',
                 'no', '1-4094', '')
      list.each do |range, pri|
        config_set('stp_global', 'vlan_priority',
                   '', range, pri)
      end
    end

    def default_vlan_priority
      config_get_default('stp_global', 'vlan_priority')
    end

    def vlan_root_priority
      config_get('stp_global', 'vlan_root_priority')
    end

    def vlan_root_priority=(list)
      config_set('stp_global', 'vlan_root_priority',
                 'no', '1-4094', '')
      list.each do |range, pri|
        config_set('stp_global', 'vlan_root_priority',
                   '', range, pri)
      end
    end

    def default_vlan_root_priority
      config_get_default('stp_global', 'vlan_root_priority')
    end

    def check_stp_mode_mst
      fail "#{caller[0][/`.*'/][1..-2]} cannot be set unless spanning-tree" \
        ' mode is mst' unless mode == 'mst'
    end
  end # class
end # module
