# November 2015, Jonathan Tripathy
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
  # SnmpNotificationReceiver - node utility class for SNMP server management
  class SnmpNotificationReceiver < NodeUtil
    attr_reader :name

    def initialize(name,
                   instantiate:      true,
                   type:             '',
                   version:          '',
                   security:         '',
                   username:         '',
                   port:             '',
                   vrf:              '',
                   source_interface: '')

      fail TypeError unless name.is_a?(String)
      @name = name

      fail TypeError unless type.is_a?(String)

      fail TypeError unless version.is_a?(String) || version.is_a?(Integer)

      fail TypeError unless security.is_a?(String)

      fail TypeError unless username.is_a?(String)

      fail TypeError unless port.is_a?(String) || port.is_a?(Integer)

      fail TypeError unless vrf.is_a?(String)

      fail TypeError unless source_interface.is_a?(String)

      return unless instantiate

      # Mandatory Properties
      fail TypeError unless name.length > 0
      fail TypeError unless type.length > 0

      if version.is_a?(Integer)
        fail TypeError if version <= 0
      else
        fail TypeError if version.length <= 0
      end

      fail TypeError unless username.length > 0

      config_set('snmp_notification_receiver',
                 'receivers',
                 state:    '',
                 ip:       name,
                 type:     type,
                 version:  version,
                 security: security,
                 username: username,
                 udp_port: port.empty? ? '' : "udp-port #{port}")

      unless source_interface.empty?
        config_set('snmp_notification_receiver',
                   'source_interface',
                   ip:               name,
                   source_interface: source_interface,
                   port:             port.empty? ? '' : "udp-port #{port}")
      end

      return if vrf.empty?
      config_set('snmp_notification_receiver',
                 'vrf',
                 ip:   name,
                 vrf:  vrf,
                 port: port.empty? ? '' : "udp-port #{port}")
    end

    def self.receivers
      hash = {}

      receivers_list = config_get('snmp_notification_receiver', 'receivers')
      return hash if receivers_list.nil?

      receivers_list.each do |arr|
        next if !arr.is_a?(Array) || arr.empty?
        id = arr[0]
        hash[id] = SnmpNotificationReceiver.new(id, instantiate: false)
      end

      hash
    end

    def ==(other)
      name == other.name
    end

    def destroy
      config_set('snmp_notification_receiver',
                 'receivers',
                 state:    'no',
                 ip:       name,
                 type:     type,
                 version:  version,
                 security: security.nil? ? '' : "#{security}",
                 username: username,
                 udp_port: port.nil? ? '' : "udp-port #{port}")
    end

    def port
      config_get('snmp_notification_receiver', 'port', @name)
    end

    def username
      if !port.nil?
        endpoint = 'username_with_port'
      else
        endpoint = 'username'
      end

      config_get('snmp_notification_receiver', endpoint, @name)
    end

    def version
      config_get('snmp_notification_receiver', 'version', @name)
    end

    def type
      config_get('snmp_notification_receiver', 'type', @name)
    end

    def security
      config_get('snmp_notification_receiver', 'security', @name)
    end

    def vrf
      config_get('snmp_notification_receiver', 'vrf', @name)
    end

    def source_interface
      val = config_get('snmp_notification_receiver', 'source_interface', @name)
      val = val.downcase unless val.nil?
      val
    end
  end
end
