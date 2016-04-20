# NXAPI implementation of encapsulation profile class
#
# March 2016, Rohan Gandhi Korlepara
#
# Copyright (c) 2014-2016 Cisco and/or its affiliates.
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
  # Encapsulation - node utility class for Encapsulation config mgmt.
  class Encapsulation < NodeUtil
    attr_reader :encap_name

    # name: name of the encap instance
    # instantiate: true = create encap instance
    def initialize(name, instantiate=true)
      fail ArgumentError unless name.length > 0
      @encap_name = name
      create if instantiate
    end

    def to_s
      "Encapsulation #{encap_name}"
    end

    # Create a hash of all current encap instances.
    def self.encaps
      return {} unless Feature.vni_enabled?
      instances = config_get('encapsulation', 'all_encaps')
      return {} if instances.nil?
      hash = {}
      instances.each do |name|
        hash[name] = Encapsulation.new(name, false)
      end
      hash
    end

    # This will expand the string to a list of bds as integers
    def self.string_to_array(string)
      list = []
      narray = string.split(',')
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

    # Enable feature and create encap instance
    def create
      Feature.vni_enable
      config_set('encapsulation', 'create', profile: @encap_name)
    end

    # Destroy an encap instance
    def destroy
      config_set('encapsulation', 'destroy', profile: @encap_name)
    end

    # ----------
    # PROPERTIES
    # ----------

    def range_summarize(string)
      Utils.array_to_str(Encapsulation.string_to_array(string.to_s), false)
    end

    def dot1q_map
      result = config_get('encapsulation', 'dot1q_map', profile: @encap_name)
      return default_dot1q_map if result.empty?

      result[0] = range_summarize(result[0])
      result[1] = range_summarize(result[1])
      result
    end

    def dot1q_map=(map)
      state = ''
      if map.empty?
        state = 'no'
        map = dot1q_map
        return if map.empty?
      end
      vlans, vnis = map
      config_set('encapsulation', 'dot1q_map', profile: @encap_name,
                 state: state, vlans: vlans, vnis: vnis)
    end

    def default_dot1q_map
      config_get_default('encapsulation', 'dot1q_map')
    end
  end
end
