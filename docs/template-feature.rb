#
# NXAPI implementation of X__CLASS_NAME__X class
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

require File.join(File.dirname(__FILE__), 'node_util')

module Cisco
  # Class name syntax will typically be the resource name in camelCase
  # format; for example: 'tacacs server host' becomes TacacsServerHost.
  class X__CLASS_NAME__X < NodeUtil
    def feature_enable
      config_set('X__RESOURCE_NAME__X', 'feature', state: '')
    end

    def feature_disable
      config_set('X__RESOURCE_NAME__X', 'feature', state: 'no')
    end

    # Check current state of the configuration
    def self.feature_enabled
      feat = config_get('X__RESOURCE_NAME__X', 'feature')
      return !(feat.nil? || feat.empty?)
    rescue Cisco::CliError => e
      # This cmd will syntax reject if feature is not
      # enabled. Just catch the reject and return false.
      return false if e.clierror =~ /Syntax error/
      raise
    end
  end
end
