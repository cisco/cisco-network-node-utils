# January 2016, Robert W Gries
#
# Copyright (c) 2015-16 Cisco and/or its affiliates.
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
  # Feature - node util class for managing common features
  class Feature < NodeUtil
    def self.fabric_enable
      # install feature-set and enable it
      config_set('feature', 'fabric', state: 'install') unless fabric_installed?
      config_set('feature', 'fabric', state: '') unless fabric_enabled?
    end

    def self.fabric_enabled?
      config_get('feature', 'fabric') =~ /^enabled/
    end

    def self.fabric_installed?
      config_get('feature', 'fabric') !~ /^uninstalled/
    end

    def self.nv_overlay_enabled?
      config_get('feature', 'nv_overlay')
    rescue Cisco::CliError => e
      # cmd will syntax when feature is not enabled.
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    def self.nv_overlay_enable
      # Note: vdc platforms restrict this feature to F3 or newer linecards
      config_set('feature', 'nv_overlay')
    end

    def self.nv_overlay_supported?
      config_set('feature', 'nv_overlay')
    rescue Cisco::CliError => e
      raise unless e.clierror =~ /not capable of supporting nv overlay feature/
      false
    end
  end
end
