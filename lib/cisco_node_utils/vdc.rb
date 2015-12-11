#
# NXAPI implementation of VDC class
#
# December 2015, Chris Van Heuveln
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

require_relative 'node_util'

module Cisco
  # node_utils class for vdc
  class Vdc < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      @vdc = (name == 'default') ? Vdc.default_vdc_name : name
      create if instantiate
    end

    def self.vdcs
      hash = {}
      vdc_list = config_get('vdc', 'all_vdcs')
      return hash if vdc_list.nil?

      vdc_list.each do |vdc_name|
        hash[vdc_name] = Vdc.new(vdc_name, false)
      end
      hash
    end

    def self.default_vdc_name
      vdc = config_get('vdc', 'default_vdc_name')
      fail RuntimeError if vdc.nil?
      vdc
    end

    def create
      fail ArgumentError,
           'There is currently no support for non-default VDCs' unless
        @vdc == Vdc.default_vdc_name
      # noop for 'default' vdc
    end

    def ==(other)
      name == other.name
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def limit_resource_module_type_f3
      config_get('vdc', 'limit_resource_module_type_f3', vdc: @vdc)
    end

    def limit_resource_module_type_f3=(state)
      state = state ? '' : 'no'
      config_set('vdc', 'limit_resource_module_type_f3',
                 state: state, vdc: @vdc)
      config_set('vdc', 'allocate_interface_unallocated', vdc: @vdc)
    end

    def default_limit_resource_module_type_f3
      config_get_default('vdc', 'limit_resource_module_type_f3')
    end
  end  # Class
end    # Module
