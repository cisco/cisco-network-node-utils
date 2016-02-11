# Mike Wiebe, January 2015
#
# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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

# Add some TACACS+ server related constants to the Cisco namespace
module Cisco
  TACACS_SERVER_ENC_NONE = 0
  TACACS_SERVER_ENC_CISCO_TYPE_7 = 7
  TACACS_SERVER_ENC_UNKNOWN = 8

  # TacacsServer - node utility class for TACACS+ server config management
  class TacacsServer < NodeUtil
    def initialize(instantiate=true)
      enable if instantiate && !TacacsServer.enabled
    end

    # Check feature enablement
    def self.enabled
      config_get('tacacs_server', 'feature')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    # Enable tacacs_server feature
    def enable
      config_set('tacacs_server', 'feature', '')
    end

    # Disable tacacs_server feature
    def destroy
      config_set('tacacs_server', 'feature', 'no')
    end

    # --------------------
    # Getters and Setters
    # --------------------

    # Set timeout
    def timeout=(timeout)
      # 'no tacacs timeout' will fail.
      # Just set it to the requested timeout value.
      config_set('tacacs_server', 'timeout', '', timeout)
    end

    # Get timeout
    def timeout
      config_get('tacacs_server', 'timeout')
    end

    # Get default timeout
    def self.default_timeout
      config_get_default('tacacs_server', 'timeout')
    end

    # Set deadtime
    def deadtime=(deadtime)
      # 'no tacacs deadtime' will fail.
      # Just set it to the requested timeout value.
      config_set('tacacs_server', 'deadtime', '', deadtime)
    end

    # Get deadtime
    def deadtime
      config_get('tacacs_server', 'deadtime')
    end

    # Get default deadtime
    def self.default_deadtime
      config_get_default('tacacs_server', 'deadtime')
    end

    # Set directed_request
    def directed_request=(state)
      fail TypeError unless state == true || state == false
      if state == TacacsServer.default_directed_request
        config_set('tacacs_server', 'directed_request', 'no')
      else
        config_set('tacacs_server', 'directed_request', '')
      end
    end

    # Check if directed request is enabled
    def directed_request?
      config_get('tacacs_server', 'directed_request')
    end

    # Get default directed_request
    def self.default_directed_request
      config_get_default('tacacs_server', 'directed_request')
    end

    # Set source interface
    def source_interface=(name)
      fail TypeError unless name.is_a? String
      if name.empty?
        config_set('tacacs_server', 'source_interface', 'no', '')
      else
        config_set('tacacs_server', 'source_interface', '', name)
      end
    end

    # Get source interface
    def source_interface
      # Sample output
      # ip tacacs source-interface Ethernet1/1
      # no tacacs source-interface
      match = config_get('tacacs_server', 'source_interface')
      return TacacsServer.default_source_interface if match.empty?
      # match_data will contain one of the following
      # [nil, " Ethernet1/1"] or ["no", nil]
      match[0] == 'no' ? TacacsServer.default_source_interface : match[1]
    end

    # Get default source interface
    def self.default_source_interface
      config_get_default('tacacs_server', 'source_interface')
    end

    # Get encryption type used for the key
    def encryption_type
      match = config_get('tacacs_server', 'encryption_type')
      match.nil? ? TACACS_SERVER_ENC_UNKNOWN : match[0].to_i
    end

    # Get default encryption type
    def self.default_encryption_type
      config_get_default('tacacs_server', 'encryption_type')
    end

    # Get encryption password
    def encryption_password
      match = config_get('tacacs_server', 'encryption_password')
      match.empty? ? TacacsServer.default_encryption_password : match[1]
    end

    # Get default encryption password
    def self.default_encryption_password
      config_get_default('tacacs_server', 'encryption_password')
    end

    # Set encryption type and password
    def encryption_key_set(enctype, password)
      # if enctype is TACACS_SERVER_ENC_UNKNOWN, we will unset the key
      if enctype == TACACS_SERVER_ENC_UNKNOWN
        # if current encryption type is not TACACS_SERVER_ENC_UNKNOWN, we
        # need to unset it. Otherwise the box is not configured with key, we
        # don't need to do anything
        if encryption_type != TACACS_SERVER_ENC_UNKNOWN
          config_set('tacacs_server', 'encryption', 'no',
                     encryption_type,
                     encryption_password)
        end
      else
        config_set('tacacs_server', 'encryption', '', enctype, password)
      end
    end
  end
end
