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
require File.expand_path("../../lib/cisco_node_utils/platform_info", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/node", __FILE__)

include Cisco

Node.lazy_connect = true # we'll specify the connection info later

class CiscoTestCase < TestCase
  @@node = nil
  @@interfaces = nil
  @@interfaces_id = nil

  def node
    unless @@node
      @@node = Node.instance
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
    puts "Platform:"
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
      begin
        platform_info = PlatformInfo.new(node.host_name)
        @@interfaces = platform_info.get_value_from_key("interfaces")
      rescue Exception => e
        # If there is a problem reading platform_info.yaml, assign default values
        default_interfaces = ["Ethernet1/1", "Ethernet1/2", "Ethernet1/3"]
        puts "Caught exception: #{e}, assigning interfaces to default - #{default_interfaces}"
        @@interfaces = default_interfaces
      end
    end
    @@interfaces
  end

  def interfaces_id
    unless @@interfaces_id
      @@interfaces_id = []
      interfaces.each { |interface|
        id = interface.split("Ethernet")[1]
        @@interfaces_id << id
      }
    end
    @@interfaces_id
  end

  # Class method method to set the class variable 'debug_flag'
  # Can be true or false.
  def self.debug_flag=(flag)
    @@debug_flag = flag
  end

  # Class method to set the class variable 'debug_method'
  # Can be name of the method or "all"
  def self.debug_method=(name)
    @@debug_method = name
  end

  # Class method to set the class variable 'debug_group'
  # Can be the name of the method or "all"
  def self.debug_group=(group)
    @@debug_group = group
  end

  # Class method to set the class variable 'debug_detail'
  # Can be true or false
  def self.debug_detail=(detail)
    @@debug_detail = detail
  end

  # Class method to dump debug data.
  # The passed in parameters will control what is printed and how.
  # Parameters:
  #   method - Name of the method the debug belongs to.
  #   group -  Name of the group the debug belongs to.
  #   indent - Indent controls the display of the data.
  #   detail - Detail controls if detail debugs should be displayed.
  #   data -   Data to be displayed. Must be a fully formatted string.
  def self.debug(method, group, indent, data)
    if (@@debug_flag) &&
       (((@@debug_method == method) || (@@debug_method == "all")) ||
       ((@@debug_group == group) || (@@debug_group == "all")))
      indent_spaces = " " * indent
      puts "#{indent_spaces}#{method} - #{data}"
    end
  end

  # Class method to dump detailed debug data.
  # The passed in parameters will control what is printed and how.
  # Parameters:
  #   method - Name of the method the debug belongs to.
  #   group -  Name of the group the debug belongs to.
  #   indent - Indent controls the display of the data.
  #   data -   Data to be displayed. Must be a fully formatted string.
  def self.debug_detail(method, group, indent, data)
    if (@@debug_detail) &&
       (((@@debug_method == method) || (@@debug_method == "all")) ||
       ((@@debug_group == group) || (@@debug_group == "all")))
      indent_spaces = " " * indent
      puts "#{indent_spaces}#{method} - #{data}"
    end
  end
end
