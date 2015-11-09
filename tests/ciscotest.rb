# Copyright (c) 2013-2015 Cisco and/or its affiliates.
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

require_relative 'basetest'
require_relative 'platform_info'
require_relative '../lib/cisco_node_utils/node'

include Cisco

Node.lazy_connect = true # we'll specify the connection info later

# CiscoTestCase - base class for all node utility minitests
class CiscoTestCase < TestCase
  # rubocop:disable Style/ClassVars
  @@node = nil
  @@interfaces = nil
  @@interfaces_id = nil
  # rubocop:enable Style/ClassVars

  def node
    unless @@node
      @@node = Node.instance # rubocop:disable Style/ClassVars
      @@node.connect(address, username, password)
      @@node.cache_enable = true
      @@node.cache_auto = true
      # Record the platform we're running on
      puts "\nNode under test:"
      puts "  - name  - #{@@node.host_name}"
      puts "  - type  - #{@@node.product_id}"
      # puts "  - image - #{@@node.system}\n\n"
    end
    @@node
  rescue Cisco::Shim::AuthenticationFailed
    abort "Unauthorized to connect as #{username}:#{password}@#{address}"
  rescue StandardError => e
    abort "Error in establishing connection: #{e}"
  end

  def setup
    super
    node
  end

  def cmd_ref
    node.cmd_ref
  end

  def platform
    node.client.platform
  end

  def config(*args)
    if node.client.platform == :ios_xr
      result = super(*args, 'commit best-effort')
    else
      result = super
    end
    node.cache_flush
    result
  end

  def interfaces
    unless @@interfaces
      # Build the platform_info, used for interface lookup
      # rubocop:disable Style/ClassVars
      platform_info = PlatformInfo.new(node.host_name, platform)
      @@interfaces = platform_info.get_value_from_key('interfaces')
      # rubocop:enable Style/ClassVars
    end
    @@interfaces
  end

  def interfaces_id
    unless @@interfaces_id
      # rubocop:disable Style/ClassVars
      @@interfaces_id = []
      interfaces.each do |interface|
        id = interface.split('Ethernet')[1]
        @@interfaces_id << id
      end
      # rubocop:enable Style/ClassVars
    end
    @@interfaces_id
  end
end
