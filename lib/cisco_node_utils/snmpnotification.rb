# December 2015
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
  # SnmpNotification - node utility class for SNMP notification management
  class SnmpNotification < NodeUtil
    def initialize(name)
      fail TypeError unless name.is_a?(String)
      @name = name
    end

    def self.notifications
      @notifications = {}
      notifs = config_get('snmpnotification', 'notifications')
      unless notifs.nil?
        notifs.each do |notif|
          @notifications[notif] = SnmpNotification.new(notif)
        end
      end
      @notifications
    end

    def destroy
      # not needed
    end

    # Set enable
    def enable=(enable)
      config_set('snmpnotification',
                 'enable',
                 state:     enable ? '' : 'no',
                 trap_name: @name)
    end

    # Get enable
    def enable
      value = config_get('snmpnotification', 'enable', trap_name: @name)
      enabled = value.nil? ? false : true
      enabled
    end
  end
end
