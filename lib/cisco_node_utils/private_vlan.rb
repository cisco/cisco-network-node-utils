# Davide Celotto Febraury 2016
# NXAPI implementation of PrivateVlan class
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

module Cisco
  # PrivateVlan - node utility class for private-vlan config mgmt.
  class PrivateVlan < NodeUtil
    def self.feature_enabled
      feat = config_get('private_vlan', 'feature')
      return !(feat.nil?)
    rescue Cisco::CliError => e
      # This cmd will syntax reject if feature is not
      # enabled. Just catch the reject and return false.
      return false if e.clierror =~ /Syntax error/
      raise
    end

    def feature_enable
      config_set('private_vlan', 'feature', '')
    end

    def feature_disable
      config_set('private_vlan', 'feature', 'no')
    end
  end
end
