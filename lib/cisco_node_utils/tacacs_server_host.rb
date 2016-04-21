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

    def initialize(name, instantiate=true, host_port=nil)
      fail TypeError unless name.is_a? String
      fail ArgumentError if name.empty?
      @name = name

      if platform == :ios_xr
        if host_port.nil?
          @port = config_get_default('tacacs_server_host', 'port')
        else
          fail ArgumentError, 'host_port must be an Integer' \
            unless host_port.is_a?(Integer)
          @port = host_port
        end
      end

      create if instantiate

      return if platform == :ios_xr

      return if host_port.nil?
      fail ArgumentError, 'host_port must be an Integer' \
        unless host_port.is_a?(Integer)
      self.port = host_port
    end

    def self.hosts
      hosts = {}
      return hosts unless Feature.tacacs_enabled?

      hosts_list = config_get('tacacs_server_host', 'hosts')
      return hosts if hosts_list.nil? || hosts_list.empty?

      hosts_list.each do |name|
        if platform == :ios_xr
          host_port = config_get('tacacs_server_host', 'port', ip: name)
          host_port = host_port[0] if host_port.is_a?(Array)
          host_port = host_port.to_i

          hosts[name] = TacacsServerHost.new(name, false, host_port)
        else
          hosts[name] = TacacsServerHost.new(name, false) if @hosts[name].nil?
        end
      end
      hosts
    end

    def create
      destroy if platform == :ios_xr
      Feature.tacacs_enable
      config_set('tacacs_server_host',
                 'host',
                 state: '',
                 ip:    name,
                 port:  @port)
    end

    def destroy
      if platform == :ios_xr
        # This provider only support a 1-1 mapping between host and ports.
        # Thus, we must remove the other entries on different ports.
        all_hosts = config_get('tacacs_server_host',
                               'host_port_pairs',
                               ip: @name)
        return unless all_hosts.is_a?(Array)

        warn("#{name} is configured multiple times on the device" \
            ' (possibly using different ports). This is unsupported by this' \
            ' API and the duplicate entries are being deleted.') \
          if all_hosts.count > 1

        all_hosts.each do |host_port|
          config_set('tacacs_server_host',
                     'host',
                     state: 'no',
                     ip:    @name,
                     port:  host_port)
        end
      else
        config_set('tacacs_server_host',
                   'host',
                   state: 'no',
                   ip:    @name,
                   port:  @port)
      end
    end

    def port
      platform == :ios_xr ? @port : config_get('tacacs_server_host',
                                               'port',
                                               ip: @name)
    end

    def port=(n)
      fail("'port' setter method not applicable for this platform." \
        'port must be passed in to the constructor.') \
          if platform == :ios_xr

      config_set('tacacs_server_host', 'port', ip: @name, port: n.to_i)
    end

    def self.default_port
      config_get_default('tacacs_server_host', 'port')
    end

    def encryption_type
      type = config_get('tacacs_server_host',
                        'encryption_type',
                        ip:   @name,
                        port: @port)
      type.nil? ? TACACS_SERVER_ENC_UNKNOWN : type.to_i
    end

    def self.default_encryption_type
      TacacsServer.default_encryption_type
    end

    def encryption_password
      config_get('tacacs_server_host',
                 'encryption_password',
                 ip:   @name,
                 port: @port)
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
          config_set('tacacs_server_host',
                     'encryption',
                     state:    'no',
                     ip:       @name,
                     port:     @port,
                     enc_type: encryption_type,
                     password: encryption_password)
        end
      else
        config_set('tacacs_server_host',
                   'encryption',
                   state:    '',
                   ip:       @name,
                   port:     @port,
                   enc_type: enctype,
                   password: password)
      end
    end

    def timeout
      config_get('tacacs_server_host',
                 'timeout',
                 ip:   @name,
                 port: @port)
    end

    def timeout=(t)
      fail TypeError unless t.is_a? Fixnum
      return if t == timeout

      config_set('tacacs_server_host',
                 'timeout',
                 state:   '',
                 ip:      @name,
                 port:    @port,
                 timeout: t)
    end

    def self.default_timeout
      config_get_default('tacacs_server_host', 'timeout')
    end

    def ==(other)
      name == other.name
    end
  end
end
