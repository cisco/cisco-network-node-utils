# David Chuck, November 2015
#
# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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
require_relative 'interface'

# Add vpc-specific constants to Cisco namespace
module Cisco
  # Vpc - node utility class for VTP configuration management
  class Vpc < NodeUtil
    attr_reader :domain
    # Constructor for Vpc
    def initialize(domain_id, instantiate=true)
      fail TypeError unless domain_id.is_a?(Integer)
      @domain = domain_id
      @set_params = {}

      create if instantiate
    end

    def self.domains
      hash = {}
      my_domain = config_get('vpc', 'domain')
      hash[my_domain] = Vpc.new(my_domain, false) unless my_domain.nil?
      hash
    end

    def self.enabled
      config_get('vpc', 'feature')
    end

    def create
      enable unless Vpc.enabled
      config_set('vpc', 'domain', state: '', domain: @domain)
    end

    def destroy
      config_set('vpc', 'feature', state: 'no')
    end

    def enable
      config_set('vpc', 'feature', state: '')
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################
    def auto_recovery
      config_get('vpc', 'auto_recovery')
    end

    def auto_recovery=(val)
      state = val ? '' : 'no'
      config_get('vpc', 'auto_recovery', state: state)
    end

    def default_auto_recovery
      config_get_default('vpc', 'auto_recovery')
    end

    def auto_recovery_reload_delay
      config_get('vpc', 'auto_recovery_reload_delay')
    end

    def auto_recovery_reload_delay=(val)
      config_get('vpc', 'auto_recovery_reload_delay', delay: val)
    end

    def default_auto_recovery_reload_delay
      config_get_default('vpc', 'auto_recovery_reload_delay')
    end

    def delay_restore
      config_get('vpc', 'delay_restore')
    end

    def delay_restore=(delay)
      config_set('vpc', 'delay_restore', delay: delay)
    end

    def default_delay_restore
      config_get_default('vpc', 'delay_restore')
    end

    def delay_restore_exclude_interface_bridge_domain
      config_get('vpc', 'delay_restore_exclude_interface_bridge_domain')
    end

    def delay_restore_exclude_interface_bridge_domain=(bdi)
      config_set('vpc', 'delay_restore_interface_vlan', bdi: bdi)
    end

    def default_delay_restore_exclude_interface_bridge_domain
      config_get_default('vpc', 'delay_restore_exclude_interface_bridge_domain')
    end

    def delay_restore_interface_vlan
      config_get('vpc', 'delay_restore_interface_vlan')
    end

    def delay_restore_interface_vlan=(svi)
      config_set('vpc', 'delay_restore_interface_vlan', svi: svi)
    end

    def default_delay_restore_interface_vlan
      config_get_default('vpc', 'delay_restore_interface_vlan')
    end
  end # class Vpc
end # module Cisco
