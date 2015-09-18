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

require File.join(File.dirname(__FILE__), 'basetest')
require File.expand_path('../../lib/cisco_node_utils/platform_info', __FILE__)
require File.expand_path('../../lib/cisco_node_utils/node', __FILE__)

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
      @@node.connect(@@address, @@username, @@password)
      @@node.cache_enable = true
      @@node.cache_auto = true
      puts "Node in CiscoTestCase Class: #{@@node}"
    end
    @@node
  end

  def process_arguments
    super
    node # Connect to device
    # Record the platform we're running on
    puts 'Platform:'
    puts "  - name  - #{@@node.host_name}"
    puts "  - type  - #{@@node.product_id}"
    puts "  - image - #{@@node.system}\n\n"
  end

  def cmd_ref
    node.cmd_ref
  end

  def interfaces
    unless @@interfaces
      # Build the platform_info, used for interface lookup
      # rubocop:disable Style/ClassVars
      begin
        platform_info = PlatformInfo.new(node.host_name)
        @@interfaces = platform_info.get_value_from_key('interfaces')
      rescue RuntimeError => e
        # If there is a problem reading platform_info.yaml, assign default values
        default_interfaces = ['Ethernet1/1', 'Ethernet1/2', 'Ethernet1/3']
        puts "Caught exception: #{e}, assigning interfaces to default - #{default_interfaces}"
        @@interfaces = default_interfaces
      end
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
