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
  class IpMulticast < NodeUtil
    def initialize(instantiate=True)
      @get_args = @set_args = {}
      Feature.ngmvpn_enable if instantiate
    end

    def destroy
      @set_args[:state] = 'no'
      config_set('ip_multicast', 'overlay_distributed_dr', @set_args)
      config_set('ip_multicast', 'overlay_spt_only', @set_args)
      Feature.ngmvpn_disable
    end

    def ip_multicast
      Feature.ngmvpn_enabled?
    end

    def overlay_distributed_dr
      config_get('ip_multicast', 'overlay_distributed_dr')
    end

    def overlay_distributed_dr=(bool)
      fail TypeError unless [true, false].include?(bool)
      @set_args[:state] = bool ? '' : 'no'
      if @set_args[:state] == 'no'
        unless overlay_distributed_dr == default_overlay_distributed_dr
          config_set('ip_multicast', 'overlay_distributed_dr', @set_args)
        end
      else
        config_set('ip_multicast', 'overlay_distributed_dr', @set_args)
      end
    end

    def default_overlay_distributed_dr
      config_get_default('ip_multicast', 'overlay_distributed_dr')
    end

    def overlay_spt_only
      config_get('ip_multicast', 'overlay_spt_only')
    end

    def overlay_spt_only=(bool)
      fail TypeError unless [true, false].include?(bool)
      @set_args[:state] = bool ? '' : 'no'
      if @set_args[:state] == 'no'
        unless overlay_spt_only == default_overlay_spt_only
          config_set('ip_multicast', 'overlay_spt_only', @set_args)
        end
      else
        config_set('ip_multicast', 'overlay_spt_only', @set_args)
      end
    end

    def default_overlay_spt_only
      config_get_default('ip_multicast', 'overlay_spt_only')
    end
  end
end
