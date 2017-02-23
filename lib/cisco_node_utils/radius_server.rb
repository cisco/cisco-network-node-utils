# Radius Server provider class

# Jonathan Tripathy et al., September 2015

# Copyright (c) 2014-2016 Cisco and/or its affiliates.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.join(File.dirname(__FILE__), 'node_util')
require 'ipaddr'

module Cisco
  # RadiusServer - node utility class for
  # Raidus Server configuration management
  class RadiusServer < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true, auth_p=nil, acct_p=nil)
      unless name =~ /^[a-zA-Z0-9\.\:]*$/
        fail ArgumentError,
             'Invalid value (IPv4/IPv6 address contains invalid characters)'
      end

      begin
        IPAddr.new(name)
      rescue
        raise ArgumentError,
              'Invalid value (Name is not a valid single IPv4/IPv6 address)'
      end
      @name = name

      if platform == :ios_xr
        if auth_p.nil?
          @auth_port = config_get_default('radius_server', 'auth-port')
        else
          fail ArgumentError, 'auth_p must be an Integer' \
            unless auth_p.is_a?(Integer)
          @auth_port = auth_p
        end

        if acct_p.nil?
          @acct_port = config_get_default('radius_server', 'acct-port')
        else
          fail ArgumentError, 'acct_p must be an Integer' \
            unless acct_p.is_a?(Integer)
          @acct_port = acct_p
        end
      end

      create if instantiate

      return if platform == :ios_xr
      unless auth_p.nil?
        fail ArgumentError, 'auth_p must be an Integer' \
          unless auth_p.is_a?(Integer)
        self.auth_port = auth_p
      end

      return if acct_p.nil?
      fail ArgumentError, 'acct_p must be an Integer' \
        unless acct_p.is_a?(Integer)
      self.acct_port = acct_p
    end

    def self.radiusservers
      hash = {}

      radiusservers_list = config_get('radius_server', 'hosts')
      return hash if radiusservers_list.empty?
      radiusservers_list.each do |id|
        if platform == :ios_xr
          authp = config_get('radius_server', 'auth-port', ip: id)
          authp = authp[0] if authp.is_a?(Array)
          authp = authp.to_i

          acctp = config_get('radius_server', 'acct-port', ip: id)
          acctp = acctp[0] if acctp.is_a?(Array)
          acctp = acctp.to_i

          hash[id] = RadiusServer.new(id, false, authp, acctp)
        else
          hash[id] = RadiusServer.new(id, false)
        end
      end

      hash
    end

    def create
      destroy if platform == :ios_xr
      config_set('radius_server',
                 'hosts',
                 state:     '',
                 ip:        @name,
                 auth_port: @auth_port,
                 acct_port: @acct_port)
    end

    def destroy
      if platform == :ios_xr
        # This provider only support a 1-1 mapping between host and ports.
        # Thus, we must remove the other entries on different ports.
        all_hosts = config_get('radius_server', 'host_port_pairs', ip: @name)
        return unless all_hosts.is_a?(Array)

        warn("#{name} is configured multiple times on the device" \
            ' (possibly using different ports). This is unsupported by this' \
            ' API and the duplicate entries are being deleted.') \
          if all_hosts.count > 1

        all_hosts.each do |host|
          auth = host[0]
          acct = host[1]

          config_set('radius_server',
                     'hosts',
                     state:     'no',
                     ip:        @name,
                     auth_port: auth,
                     acct_port: acct)
        end
      else
        config_set('radius_server',
                   'hosts',
                   state:     'no',
                   ip:        @name,
                   auth_port: @auth_port,
                   acct_port: @acct_port)
      end
    end

    def ==(other)
      name == other.name
    end

    def auth_port
      platform == :ios_xr ? @auth_port : config_get('radius_server',
                                                    'auth-port', ip: @name)
    end

    def default_auth_port
      config_get_default('radius_server', 'auth-port')
    end

    def auth_port=(val)
      fail("'auth_port' setter method not applicable for this platform." \
        'auth_port must be passed in to the constructor.') \
          if platform == :ios_xr

      unless val.nil?
        fail ArgumentError, 'auth_port must be an Integer' \
          unless val.is_a?(Integer)
      end

      if val.nil?
        config_set('radius_server',
                   'auth-port',
                   state: 'no',
                   ip:    @name,
                   port:  auth_port)
      else
        config_set('radius_server',
                   'auth-port',
                   state: '',
                   ip:    @name,
                   port:  val)
      end
    end

    def acct_port
      platform == :ios_xr ? @acct_port : config_get('radius_server',
                                                    'acct-port', ip: @name)
    end

    def default_acct_port
      config_get_default('radius_server', 'acct-port')
    end

    def acct_port=(val)
      fail("'acct_port' setter method not applicable for this platform." \
        'acct_port must be passed in to the constructor.') \
          if platform == :ios_xr

      unless val.nil?
        fail ArgumentError, 'acct_port must be an Integer' \
          unless val.is_a?(Integer)
      end

      if val.nil?
        config_set('radius_server',
                   'acct-port',
                   state: 'no',
                   ip:    @name,
                   port:  acct_port)
      else
        config_set('radius_server',
                   'acct-port',
                   state: '',
                   ip:    @name,
                   port:  val)
      end
    end

    def timeout
      val = config_get('radius_server',
                       'timeout',
                       ip:        @name,
                       auth_port: @auth_port,
                       acct_port: @acct_port)

      val = val[0] if val.is_a?(Array)
      val = val.to_i unless val.nil?
      val
    end

    def default_timeout
      config_get_default('radius_server', 'timeout')
    end

    def timeout=(val)
      unless val.nil?
        fail ArgumentError, 'timeout must be an Integer' \
          unless val.is_a?(Integer)
      end

      if val.nil?
        return if timeout.nil?
        config_set('radius_server',
                   'timeout',
                   state:     'no',
                   ip:        @name,
                   auth_port: @auth_port,
                   acct_port: @acct_port,
                   timeout:   timeout)
      else
        config_set('radius_server',
                   'timeout',
                   state:     '',
                   ip:        @name,
                   auth_port: @auth_port,
                   acct_port: @acct_port,
                   timeout:   val)
      end
    end

    def retransmit_count
      val = config_get('radius_server',
                       'retransmit',
                       ip:        @name,
                       auth_port: @auth_port,
                       acct_port: @acct_port)
      val = val[0] if val.is_a?(Array)
      val = val.to_i unless val.nil?
      val
    end

    def default_retransmit_count
      config_get_default('radius_server', 'retransmit')
    end

    def retransmit_count=(val)
      unless val.nil?
        fail ArgumentError, 'retransmit_count must be an Integer' \
          unless val.is_a?(Integer)
      end

      if val.nil?
        return if retransmit_count.nil?
        config_set('radius_server',
                   'retransmit',
                   state:     'no',
                   ip:        @name,
                   auth_port: @auth_port,
                   acct_port: @acct_port,
                   count:     retransmit_count)
      else
        config_set('radius_server',
                   'retransmit',
                   state:     '',
                   ip:        @name,
                   auth_port: @auth_port,
                   acct_port: @acct_port,
                   count:     val)
      end
    end

    def accounting
      return nil if platform == :ios_xr
      val = config_get('radius_server', 'accounting', ip: @name)
      if val.nil?
        false
      else
        val
      end
    end

    def default_accounting
      config_get_default('radius_server', 'accounting')
    end

    def accounting=(val)
      if !val
        config_set('radius_server',
                   'accounting',
                   state: 'no',
                   ip:    @name)
      else
        config_set('radius_server',
                   'accounting',
                   state: '',
                   ip:    @name)
      end
    end

    def authentication
      return nil if platform == :ios_xr
      val = config_get('radius_server', 'authentication', ip: @name)
      if val.nil?
        false
      else
        val
      end
    end

    def default_authentication
      config_get_default('radius_server', 'authentication')
    end

    def authentication=(val)
      if !val
        config_set('radius_server',
                   'authentication',
                   state: 'no',
                   ip:    @name)
      else
        config_set('radius_server',
                   'authentication',
                   state: '',
                   ip:    @name)
      end
    end

    def key_format
      val = config_get('radius_server',
                       'key_format',
                       ip:        @name,
                       auth_port: @auth_port,
                       acct_port: @acct_port)

      val = val[0] if val.is_a?(Array)
      val
    end

    def key
      val = config_get('radius_server',
                       'key',
                       ip:        @name,
                       auth_port: @auth_port,
                       acct_port: @acct_port)

      val = val[0] if val.is_a?(Array)
      return if val.nil? || val.empty?
      index = val.index('auth-port')
      val = val[0..index - 2] unless index.nil?
      val = val.strip
      Utils.add_quotes(val)
    end

    def key_set(value, format)
      unless value.nil?
        fail ArgumentError, 'value must be a String' \
          unless value.is_a?(String)
      end

      unless format.nil?
        fail ArgumentError, 'format must be an Integer' \
          unless format.is_a?(Integer)
      end

      # Return as we don't need to do anything
      return if value.nil? && key.nil?

      if value.nil? && !key.nil?
        config_set('radius_server',
                   'key',
                   state:     'no',
                   ip:        @name,
                   auth_port: @auth_port,
                   acct_port: @acct_port,
                   key:       "#{key_format} #{key}")
      elsif !format.nil?
        value = Utils.add_quotes(value)
        config_set('radius_server',
                   'key',
                   state:     '',
                   ip:        @name,
                   auth_port: @auth_port,
                   acct_port: @acct_port,
                   key:       "#{format} #{value}")
      else
        value = Utils.add_quotes(value)
        config_set('radius_server',
                   'key',
                   state:     '',
                   ip:        @name,
                   auth_port: @auth_port,
                   acct_port: @acct_port,
                   key:       "#{value}")
      end
    end
  end # class
end # module
