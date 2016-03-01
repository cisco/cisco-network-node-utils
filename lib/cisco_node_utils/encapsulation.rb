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
require_relative 'feature'
require_relative 'vdc'

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

    # Create a hash of all current encap instances.
    def self.all_encaps
      instances = config_get('encapsulation', 'all_encaps')
      return {} if instances.nil?
      hash = {}
      instances.each do |name|
        hash[name] = Encapsulation.new(name, false)
      end
      hash
    end

    def cli_error_check(result)
      # The NXOS encap profile cli does not raise an exception in some
      # conditions and instead just displays a STDOUT error message;
      # thus NXAPI does not detect the failure and we must catch it by
      # inspecting the "body" hash entry returned by NXAPI. This
      # encap profile cli behavior is unlikely to change.
      fail result[2]['body'] if
        result[2].is_a?(Hash) &&
        /(ERROR:|Warning:)/.match(result[2]['body'].to_s)

      # Some test environments get result[2] as a string instead of a hash
      fail result[2] if
        result[2].is_a?(String) &&
        /(ERROR:|Warning:)/.match(result[2])
    end

    # Enable feature and create encap instance
    def create
      vdc = Vdc.new('default')
      vdc.limit_resource_module_type = 'f3' unless
        vdc.limit_resource_module_type == 'f3'
      Feature.vni_enable unless Feature.vni_enabled?
      result = config_set('encapsulation', 'create', @encap_name)
      cli_error_check(result)
    rescue CliError => e
      raise "[encapsulation #{@encap_name}] '#{e.command}' : #{e.clierror}"
    end

    # Destroy a encap instance; disable feature on last instance
    def destroy
      result = config_set('encapsulation', 'destroy', @encap_name)
      cli_error_check(result)
    rescue CliError => e
      raise "[encapsulation #{@encap_name}] '#{e.command}' : #{e.clierror}"
    end

    # ----------
    # PROPERTIES
    # ----------

    def dot1q_map
      config_get('encapsulation', 'dot1q_map', @encap_name)
    end

    def set_dot1q_map=(cmd, dot1q, vni)
      no_cmd = (cmd) ? '' : 'no'
      result = config_set('encapsulation', 'dot1q_map', @encap_name,
                          no_cmd, dot1q, vni)
      cli_error_check(result)
    rescue CliError => e
      raise "[encapsulation #{@encap_name}] '#{e.command}' : #{e.clierror}"
    end

    def default_dot1q_map
      config_get_default('encapsulation', 'dot1q_map')
    end
  end
end
