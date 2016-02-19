# February 2016, Sai Chintalapudi
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

module Cisco
  # node_utils class for itd_device_group
  class ItdDeviceGroup < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name.length > 0
      @name = name

      create if instantiate
    end

    def self.groups
      hash = {}
      # sometimes the name has extra stuff which needs to be removed
      group_list = config_get('interface', 'all_itd_device_groups').split[0]
      return hash if group_list.nil?

      group_list.each do |id|
        hash[id] = ItdDeviceGroup.new(id, false)
      end
      hash
    end

    def create
      config_set('itd_device_group', 'feature_itd', '') unless
        config_get('itd_device_group', 'feature_itd') == true
      config_set('itd_device_group', 'create', @name)
    end

    def destroy
      config_set('itd_device_group', 'destroy', @name)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def probe
      params = config_get('itd_device_group', 'probe')
      hash = {}
      return hash if params.nil?
      hash[:probe_frequency] = params[1]
      hash[:probe_timeout] = params[2]
      hash[:probe_retry_down] = params[3]
      hash[:probe_retry_up] = params[4]
      hash[:probe_control] = false

      lparams = params[0].split
      hash[:probe_type] = lparams[0]
      case hash[:probe_type].to_sym
      when :dns
        hash[:probe_dns_host] = lparams[2]
      when :tcp
        hash[:probe_port] = lparams[2]
        hash[:probe_control] = true unless lparams[3].nil?
      when :udp
        hash[:probe_port] = lparams[2]
        hash[:probe_control] = true unless lparams[3].nil?
      end
      hash
    end

    def probe_control
      hash = probe
      hash[:probe_control]
    end

    def default_probe_control
      config_get_default('itd_device_group', 'probe_control')
    end

    def probe_dns_host
      hash = probe
      hash[:probe_dns_host]
    end

    def probe_frequency
      hash = probe
      hash[:probe_frequency]
    end

    def default_probe_frequency
      config_get_default('itd_device_group', 'probe_frequency')
    end

    def probe_port
      hash = probe
      hash[:probe_port]
    end

    def probe_retry_down
      hash = probe
      hash[:probe_retry_down]
    end

    def default_probe_retry_down
      config_get_default('itd_device_group', 'probe_retry_down')
    end

    def probe_retry_up
      hash = probe
      hash[:probe_retry_up]
    end

    def default_probe_retry_up
      config_get_default('itd_device_group', 'probe_retry_up')
    end

    def probe_timeout
      hash = probe
      hash[:probe_timeout]
    end

    def default_probe_timeout
      config_get_default('itd_device_group', 'probe_timeout')
    end

    def probe_type
      hash = probe
      hash[:probe_type]
    end

    def default_probe_type
      config_get_default('itd_device_group', 'probe_type')
    end

    def probe=(type, host, control, freq, ret_up, ret_down, port, timeout)
      if type == false
        config_set('itd_device_group', 'probe_type', 'no')
        return
      end
      case type.to_sym
      when :dns
        config_set('itd_device_group', 'probe', type, 'host', host, '',
                   freq, timeout, ret_down, ret_up)
      when :tcp
        if control
          config_set('itd_device_group', 'probe', type, 'port', port,
                     'control enable', freq, timeout, ret_down, ret_up)
        else
          config_set('itd_device_group', 'probe', type, 'port', port, '',
                     freq, timeout, ret_down, ret_up)
        end
      when :udp
        if control
          config_set('itd_device_group', 'probe', type, 'port', port,
                     'control enable', freq, timeout, ret_down, ret_up)
        else
          config_set('itd_device_group', 'probe', type, 'port', port, '',
                     freq, timeout, ret_down, ret_up)
        end
      when :icmp
        config_set('itd_device_group', 'probe', type, '', '', '',
                   freq, timeout, ret_down, ret_up)
      end
    end
  end  # Class
end    # Module
