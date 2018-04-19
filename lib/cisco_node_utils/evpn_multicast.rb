# January 2018, Rahul Shenoy
#
# Copyright (c) 2018 Cisco and/or its affiliates.
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

require_relative 'cisco_cmn_utils'
require_relative 'node_util'
require_relative 'feature'

module Cisco
  # node_utils class for evpn_multisite
  class EvpnMulticast < NodeUtil
    def initialize
      @get_args = @set_args = {}
      create
    end

    def create
      return unless multicast == default_multicast
      Feature.ngmvpn_enable
      config_set('feature', 'nv_overlay', state: '')
      @set_args[:state] = ''
      config_set('evpn_multicast', 'multicast', @set_args)
    end

    def destroy
      @set_args[:state] = 'no'
      config_set('evpn_multicast', 'multicast', @set_args)
    end

    def self.multicast
      config_get('evpn_multicast', 'multicast')
    end

    def multicast
      config_get('evpn_multicast', 'multicast')
    end

    def multicast=(bool)
      fail TypeError unless [true, false].include?(bool)
      @set_args[:state] = bool ? '' : 'no'
      if @set_args[:state] == 'no'
        unless multicast == default_multicast
          config_set('evpn_multicast', 'multicast', @set_args)
        end
      else
        config_set('evpn_multicast', 'multicast', @set_args)
      end
    end

    def default_multicast
      config_get_default('evpn_multicast', 'multicast')
    end
  end
end
