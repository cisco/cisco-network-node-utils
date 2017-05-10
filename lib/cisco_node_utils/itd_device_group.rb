# February 2016, Sai Chintalapudi
#
# Copyright (c) 2016 Cisco and/or its affiliates.
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
  # node_utils class for itd_device_group
  class ItdDeviceGroup < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name.length > 0
      @name = name

      set_args_keys_default
      create if instantiate
    end

    def self.itds
      hash = {}
      groups = config_get('itd_device_group',
                          'all_itd_device_groups')
      return hash if groups.nil?

      groups.each do |id|
        hash[id] = ItdDeviceGroup.new(id, false)
      end
      hash
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def create
      Feature.itd_enable
      config_set('itd_device_group', 'create', name: @name)
    end

    def destroy
      config_set('itd_device_group', 'destroy', name: @name)
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      keys = { name: @name }
      @get_args = @set_args = keys
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    # probe configuration is all done in a single line (like below)
    # probe tcp port 32 frequency 10 timeout 5 retry-down-count 3 ...
    # probe udp port 23 frequency 10 timeout 5 retry-down-count 3 ...
    # probe icmp frequency 10 timeout 5 retry-down-count 3 retry-up-count 3
    # probe dns host 8.8.8.8 frequency 10 timeout 5 retry-down-count 3 ...
    # also the 'control enable' can be set if the type is tcp or udp only
    # probe udp port 23 control enable frequency 10 timeout 5 ...
    def probe_get
      str = config_get('itd_device_group', 'probe', @get_args)
      return nil if str.nil?
      regexp = Regexp.new('(?<type>\S+)'\
                 ' *(?<dns_host>host \S+)?'\
                 ' *(?<port>port \d+)?'\
                 ' *(?<control>control \S+)?'\
                 ' *(?<frequency>frequency \d+)?'\
                 ' *(?<timeout>timeout \d+)'\
                 ' *(?<retry_down>retry-down-count \d+)'\
                 ' *(?<retry_up>retry-up-count \d+)')
      regexp.match(str)
    end

    def probe_control
      val = Utils.extract_value(probe_get, 'control')
      return default_probe_control if val.nil?
      val == 'enable' ? true : default_probe_control
    end

    def probe_control=(control)
      if control
        @set_args[:control] = 'control enable'
      else
        @set_args[:control] = ''
      end
    end

    def default_probe_control
      config_get_default('itd_device_group', 'probe_control')
    end

    def probe_dns_host
      Utils.extract_value(probe_get, 'dns_host', 'host')
    end

    def probe_dns_host=(dns_host)
      @set_args[:dns_host] = Utils.attach_prefix(dns_host, :dns_host, 'host')
    end

    def probe_frequency
      val = Utils.extract_value(probe_get, 'frequency')
      return default_probe_frequency if val.nil?
      val.to_i
    end

    def probe_frequency=(frequency)
      @set_args[:frequency] = Utils.attach_prefix(frequency, :frequency)
    end

    def default_probe_frequency
      config_get_default('itd_device_group', 'probe_frequency')
    end

    def probe_port
      val = Utils.extract_value(probe_get, 'port')
      val.to_i unless val.nil?
    end

    def probe_port=(port)
      @set_args[:port] = Utils.attach_prefix(port, :port)
    end

    def probe_retry_down
      val = Utils.extract_value(probe_get, 'retry_down', 'retry-down-count')
      return default_probe_retry_down if val.nil?
      val.to_i
    end

    def probe_retry_down=(rdc)
      @set_args[:retry_down_count] = Utils.attach_prefix(rdc,
                                                         :retry_down_count,
                                                         'retry-down-count')
    end

    def default_probe_retry_down
      config_get_default('itd_device_group', 'probe_retry_down')
    end

    def probe_retry_up
      val = Utils.extract_value(probe_get, 'retry_up', 'retry-up-count')
      return default_probe_retry_up if val.nil?
      val.to_i
    end

    def probe_retry_up=(ruc)
      @set_args[:retry_up_count] = Utils.attach_prefix(ruc,
                                                       :retry_up_count,
                                                       'retry-up-count')
    end

    def default_probe_retry_up
      config_get_default('itd_device_group', 'probe_retry_up')
    end

    def probe_timeout
      val = Utils.extract_value(probe_get, 'timeout')
      return default_probe_timeout if val.nil?
      val.to_i
    end

    def probe_timeout=(timeout)
      @set_args[:timeout] = Utils.attach_prefix(timeout, :timeout)
    end

    def default_probe_timeout
      config_get_default('itd_device_group', 'probe_timeout')
    end

    def probe_type
      match = probe_get
      return default_probe_type if match.nil?
      match.names.include?('type') ? match[:type] : default_probe_type
    end

    def probe_type=(type)
      @set_args[:type] = type
    end

    def default_probe_type
      config_get_default('itd_device_group', 'probe_type')
    end

    def probe_set(attrs)
      if attrs[:probe_type] == false
        cmd = 'probe_type'
        @set_args[:state] = 'no'
      else
        cmd = 'probe'
        set_args_keys_default
        set_args_keys(attrs)
        [:probe_type,
         :probe_dns_host,
         :probe_port,
         :probe_control,
         :probe_frequency,
         :probe_timeout,
         :probe_retry_down,
         :probe_retry_up,
        ].each do |p|
          attrs[p] = '' if attrs[p].nil?
          send(p.to_s + '=', attrs[p])
        end
        # for boolean we need to do this
        send('probe_control=', false) if attrs[:probe_control] == ''
        @get_args = @set_args
      end
      config_set('itd_device_group', cmd, @set_args)
      set_args_keys_default
    end
  end  # Class
end    # Module
