#
# NXAPI implementation of SnmpCommunity class
#
# November 2014, Alex Hunsberger
#
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

require File.join(File.dirname(__FILE__), 'node')

module Cisco
class SnmpServer
  @@node = Cisco::Node.instance

  def aaa_user_cache_timeout
    match = @@node.config_get("snmp_server", "aaa_user_cache_timeout")
    # regex in yaml returns an array result, use .first to get match
    match.nil? ? default_aaa_user_cache_timeout : match.first.to_i
  end

  def aaa_user_cache_timeout=(timeout)
    if timeout == default_aaa_user_cache_timeout
      @@node.config_set("snmp_server", "aaa_user_cache_timeout", "no",
                        aaa_user_cache_timeout)
    else
      @@node.config_set("snmp_server", "aaa_user_cache_timeout", "", timeout)
    end
  end

  def default_aaa_user_cache_timeout
    @@node.config_get_default("snmp_server", "aaa_user_cache_timeout")
  end

  def location
    match = @@node.config_get("snmp_server", "location")
    match.nil? ? default_location : match
  end

  def location=(location)
    raise TypeError unless location.is_a?(String)
    if location.empty?
      @@node.config_set("snmp_server", "location", "no", "")
    else
      @@node.config_set("snmp_server", "location", "", location)
    end
  end

  def default_location
    @@node.config_get_default("snmp_server", "location")
  end

  def contact
    match = @@node.config_get("snmp_server", "contact")
    match.nil? ? default_contact : match
  end

  def contact=(contact)
    raise TypeError unless contact.is_a?(String)
    if contact.empty?
      @@node.config_set("snmp_server", "contact", "no", "")
    else
      @@node.config_set("snmp_server", "contact", "", contact)
    end
  end

  def default_contact
    @@node.config_get_default("snmp_server", "contact")
  end

  def packet_size
    match = @@node.config_get("snmp_server", "packet_size")
    # regex in yaml returns an array result, use .first to get match
    match.nil? ? default_packet_size : match.first.to_i
  end

  def packet_size=(size)
    if size == 0
      ps = packet_size
      @@node.config_set("snmp_server", "packet_size", "no", ps) unless ps == 0
    else
      @@node.config_set("snmp_server", "packet_size", "", size)
    end
  end

  def default_packet_size
    @@node.config_get_default("snmp_server", "packet_size")
  end

  def global_enforce_priv?
    not @@node.config_get("snmp_server", "global_enforce_priv").nil?
  end

  def global_enforce_priv=(enforce)
    if enforce
      @@node.config_set("snmp_server", "global_enforce_priv", "")
    else
      @@node.config_set("snmp_server", "global_enforce_priv", "no")
    end
  end

  def default_global_enforce_priv
    @@node.config_get_default("snmp_server", "global_enforce_priv")
  end

  def protocol?
    match = @@node.config_get("snmp_server", "protocol")
    not match.nil? and match.include?("Enable")
  end

  def protocol=(enable)
    if enable
      @@node.config_set("snmp_server", "protocol", "")
    else
      @@node.config_set("snmp_server", "protocol", "no")
    end
  end

  def default_protocol
    @@node.config_get_default("snmp_server", "protocol")
  end

  def tcp_session_auth?
    match = @@node.config_get("snmp_server", "tcp_session_auth")
    not match.nil? and match.include?("Enabled")
  end

  def tcp_session_auth=(enable)
    if enable
      @@node.config_set("snmp_server", "tcp_session_auth", "", "auth")
    else
      @@node.config_set("snmp_server", "tcp_session_auth", "no", "")
    end
  end

  def default_tcp_session_auth
    @@node.config_get_default("snmp_server", "tcp_session_auth")
  end
end
end
