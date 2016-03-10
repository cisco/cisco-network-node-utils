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
      @set_args = { name: @name }
      @get_args = @set_args
    end

    # extract value of property from probe
    def extract_value(prop, prefix=nil)
      prefix = prop if prefix.nil?
      probe_match = probe_get

      # matching probe not found
      return nil if probe_match.nil? # no matching probe found

      # property not defined for matching probe
      return nil unless probe_match.names.include?(prop)

      # extract and return value that follows prefix + <space>
      regexp = Regexp.new("#{Regexp.escape(prefix)} (?<extracted>.*)")
      value_match = regexp.match(probe_match[prop])
      return nil if value_match.nil?
      value_match[:extracted]
    end

    # prepend property name prefix/keyword to value
    def attach_prefix(val, prop, prefix=nil)
      prefix = prop.to_s if prefix.nil?
      @set_args[prop] = val.to_s.empty? ? val : "#{prefix} #{val}"
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
      val = extract_value('control')
      return default_probe_control if val.nil?
      val == 'enable' ? true : default_probe_control
    end

    def default_probe_control
      config_get_default('itd_device_group', 'probe_control')
    end

    def probe_dns_host
      extract_value('dns_host', 'host')
    end

    def probe_frequency
      val = extract_value('frequency')
      return default_probe_frequency if val.nil?
      val.to_i
    end

    def default_probe_frequency
      config_get_default('itd_device_group', 'probe_frequency')
    end

    def probe_port
      val = extract_value('port')
      val.to_i unless val.nil?
    end

    def probe_retry_down
      val = extract_value('retry_down', 'retry-down-count')
      return default_probe_retry_down if val.nil?
      val.to_i
    end

    def default_probe_retry_down
      config_get_default('itd_device_group', 'probe_retry_down')
    end

    def probe_retry_up
      val = extract_value('retry_up', 'retry-up-count')
      return default_probe_retry_up if val.nil?
      val.to_i
    end

    def default_probe_retry_up
      config_get_default('itd_device_group', 'probe_retry_up')
    end

    def probe_timeout
      val = extract_value('timeout')
      return default_probe_timeout if val.nil?
      val.to_i
    end

    def default_probe_timeout
      config_get_default('itd_device_group', 'probe_timeout')
    end

    def probe_type
      match = probe_get
      return default_probe_type if match.nil?
      match.names.include?('type') ? match[:type] : default_probe_type
    end

    def default_probe_type
      config_get_default('itd_device_group', 'probe_type')
    end

    def probe=(type, host, control, freq, ret_up, ret_down, port, timeout)
      if type == false
        @set_args[:state] = 'no'
        config_set('itd_device_group', 'probe_type', @set_args)
        set_args_keys_default
        return
      end
      @set_args[:type] = type
      @set_args[:freq] = freq
      @set_args[:to] = timeout
      @set_args[:rdc] = ret_down
      @set_args[:ruc] = ret_up
      case type.to_sym
      when :dns
        @set_args[:hps] = 'host'
        @set_args[:hpv] = host
        @set_args[:control] = ''
        config_set('itd_device_group', 'probe', @set_args)
      when :tcp, :udp
        control_str = control ? 'control enable' : ''
        @set_args[:hps] = 'port'
        @set_args[:hpv] = port
        @set_args[:control] = control_str
        config_set('itd_device_group', 'probe', @set_args)
      when :icmp
        @set_args[:hps] = ''
        @set_args[:hpv] = ''
        @set_args[:control] = ''
        config_set('itd_device_group', 'probe', @set_args)
      end
      set_args_keys_default
    end
  end  # Class
end    # Module
