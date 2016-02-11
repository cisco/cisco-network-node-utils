# Alex Hunsberger, March 2015
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
require_relative 'tacacs_server'

module Cisco
  # TacacsServerHost - node utility class for TACACS+ server host config
  class TacacsServerHost < NodeUtil
    attr_reader :name
    @hosts = {}

    def initialize(name, create=true)
      fail TypeError unless name.is_a? String
      fail ArgumentError if name.empty?
      @name = name
      return unless create
      # 'feature tacacs+' must be enabled to create a host
      TacacsServer.new.enable unless TacacsServer.enabled
      config_set('tacacs_server_host', 'host', '', name)
    end

    def self.hosts
      @hosts = {}

      return @hosts unless TacacsServer.enabled

      hosts = config_get('tacacs_server_host', 'hosts')
      unless hosts.nil?
        hosts = [hosts] if hosts.is_a?(Hash)
        hosts.each do |name|
          @hosts[name] = TacacsServerHost.new(name, false) if @hosts[name].nil?
        end
      end
      @hosts
    end

    def destroy
      config_set('tacacs_server_host', 'host', 'no', @name)
    end

    def port
      config_get('tacacs_server_host', 'port', @name)
    end

    def port=(n)
      config_set('tacacs_server_host', 'port', @name, n.to_i)
    end

    def self.default_port
      config_get_default('tacacs_server_host', 'port')
    end

    def encryption_type
      type = config_get('tacacs_server_host', 'encryption_type', @name)
      type.nil? ? TACACS_SERVER_ENC_UNKNOWN : type.to_i
    end

    def self.default_encryption_type
      TacacsServer.default_encryption_type
    end

    def encryption_password
      config_get('tacacs_server_host', 'encryption_password', @name)
    end

    def self.default_encryption_password
      config_get_default('tacacs_server_host', 'encryption_password')
    end

    def encryption_key_set(enctype, password)
      fail TypeError unless enctype.is_a? Fixnum
      fail ArgumentError if password && ![TACACS_SERVER_ENC_NONE,
                                          TACACS_SERVER_ENC_CISCO_TYPE_7,
                                          TACACS_SERVER_ENC_UNKNOWN,
                                         ].include?(enctype)
      # if enctype is TACACS_SERVER_ENC_UNKNOWN, we'll unset the key
      if enctype == TACACS_SERVER_ENC_UNKNOWN
        # if current encryption type is not TACACS_SERVER_ENC_UNKNOWN, we need
        # to unset the key value. Otherwise, the box is not configured with key,
        # thus we don't need to do anything
        if encryption_type != TACACS_SERVER_ENC_UNKNOWN
          config_set('tacacs_server_host', 'encryption', 'no', @name,
                     encryption_type,
                     encryption_password)
        end
      else
        config_set('tacacs_server_host', 'encryption',
                   '', @name, enctype, password)
      end
    end

    def timeout
      config_get('tacacs_server_host', 'timeout', @name)
    end

    def timeout=(t)
      fail TypeError unless t.is_a? Fixnum
      return if t == timeout

      config_set('tacacs_server_host', 'timeout', '', @name, t)
    end

    def self.default_timeout
      config_get_default('tacacs_server_host', 'timeout')
    end
  end
end
