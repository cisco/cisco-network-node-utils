# November 2014, Alex Hunsberger
#
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
  # SnmpServer - node utility class for SNMP server management
  class SnmpServer < NodeUtil
    def aaa_user_cache_timeout
      config_get('snmp_server', 'aaa_user_cache_timeout')
    end

    def aaa_user_cache_timeout=(timeout)
      if timeout == default_aaa_user_cache_timeout
        config_set('snmp_server', 'aaa_user_cache_timeout', 'no',
                   aaa_user_cache_timeout)
      else
        config_set('snmp_server', 'aaa_user_cache_timeout', '', timeout)
      end
    end

    def default_aaa_user_cache_timeout
      config_get_default('snmp_server', 'aaa_user_cache_timeout')
    end

    def location
      match = config_get('snmp_server', 'location')
      match.nil? ? default_location : match
    end

    def location=(location)
      fail TypeError unless location.is_a?(String)
      if location.empty?
        config_set('snmp_server', 'location', 'no', '')
      else
        config_set('snmp_server', 'location', '', location)
      end
    end

    def default_location
      config_get_default('snmp_server', 'location')
    end

    def contact
      match = config_get('snmp_server', 'contact')
      match.nil? ? default_contact : match
    end

    def contact=(contact)
      fail TypeError unless contact.is_a?(String)
      if contact.empty?
        config_set('snmp_server', 'contact', 'no', '')
      else
        config_set('snmp_server', 'contact', '', contact)
      end
    end

    def default_contact
      config_get_default('snmp_server', 'contact')
    end

    def packet_size
      config_get('snmp_server', 'packet_size')
    end

    def packet_size=(size)
      if size == 0
        ps = packet_size
        config_set('snmp_server', 'packet_size', 'no', ps) unless ps == 0
      else
        config_set('snmp_server', 'packet_size', '', size)
      end
    end

    def default_packet_size
      config_get_default('snmp_server', 'packet_size')
    end

    def global_enforce_priv?
      config_get('snmp_server', 'global_enforce_priv')
    end

    def global_enforce_priv=(enforce)
      if enforce
        config_set('snmp_server', 'global_enforce_priv', '')
      else
        config_set('snmp_server', 'global_enforce_priv', 'no')
      end
    end

    def default_global_enforce_priv
      config_get_default('snmp_server', 'global_enforce_priv')
    end

    def protocol?
      config_get('snmp_server', 'protocol')
    end

    def protocol=(enable)
      no_cmd = (enable ? '' : 'no')
      config_set('snmp_server', 'protocol', no_cmd)
    end

    def default_protocol
      config_get_default('snmp_server', 'protocol')
    end

    def tcp_session_auth?
      config_get('snmp_server', 'tcp_session_auth')
    end

    def tcp_session_auth=(enable)
      if enable
        config_set('snmp_server', 'tcp_session_auth', '', 'auth')
      else
        config_set('snmp_server', 'tcp_session_auth', 'no', '')
      end
    end

    def default_tcp_session_auth
      config_get_default('snmp_server', 'tcp_session_auth')
    end
  end
end
