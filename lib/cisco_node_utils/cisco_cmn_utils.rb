# Common Utilities for Puppet Resources.
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

# Add some general-purpose constants and APIs to the Cisco namespace
module Cisco
  # global constants
  DEFAULT_INSTANCE_NAME = 'default'

  # Encryption - helper class for translating encryption type CLI
  class Encryption
    # password encryption types
    def self.cli_to_symbol(cli)
      case cli
      when '0', 0
        :cleartext
      when '3', 3
        :"3des" # yuck :-(
      when '5', 5
        :md5
      when '6', 6
        :aes
      when '7', 7
        :cisco_type_7
      else
        fail KeyError
      end
    end

    def self.symbol_to_cli(symbol)
      symbol = symbol.downcase if symbol.is_a? String
      case symbol
      when :cleartext, :none, 'cleartext', 'none', '0', 0
        '0'
      when :"3des", '3des', '3', 3
        '3'
      when :md5, 'md5', '5', 5
        '5'
      when :aes, 'aes', '6', 6
        '6'
      when :cisco_type_7, :type_7, 'cisco_type_7', 'type_7', '7', 7
        '7'
      else
        fail KeyError
      end
    end
  end

  # ChefUtils - helper class for Chef code generation
  class ChefUtils
    def self.generic_prop_set(klass, rlbname, props)
      props.each do |prop|
        klass.instance_eval do
          # Helper Chef setter method, e.g.:
          #   if @new_resource.foo.nil?
          #     def_prop = @rlb.default_foo
          #     @new_resource.foo(def_prop)
          #   end
          #   current = @rlb.foo
          #   if current != @new_resource.foo
          #     converge_by("update foo '#{current}' => " +
          #                 "'#{@new_resource.foo}'") do
          #       @rlb.foo=(@new_resource.foo)
          #     end
          #   end
          if @new_resource.send(prop).nil?
            def_prop = instance_variable_get(rlbname).send("default_#{prop}")
            # Set resource to default if recipe property is not specified
            @new_resource.send(prop, def_prop)
          end
          current = instance_variable_get(rlbname).send(prop)
          if current != @new_resource.send(prop)
            converge_by("update #{prop} '#{current}' => " \
                        "'#{@new_resource.send(prop)}'") do
              instance_variable_get(rlbname).send("#{prop}=",
                                                  @new_resource.send(prop))
            end
          end
        end
      end
    end
  end # class ChefUtils

  # General utility class
  class Utils
    require 'ipaddr'
    # Helper utility method for ip/prefix format networks.
    # For ip/prefix format '1.1.1.1/24' or '2000:123:38::34/64',
    # we need to mask the address using the prefix length so that they
    # are converted to '1.1.1.0/24' or '2000:123:38::/64'
    def self.process_network_mask(network)
      mask = network.split('/')[1]
      address = IPAddr.new(network).to_s
      network = address + '/' + mask unless mask.nil?
      network
    end

    # Helper to build a hash of add/remove commands for a nested array.
    # Useful for network, redistribute, etc.
    #   should: an array of expected cmds (manifest/recipe)
    #  current: an array of existing cmds on the device
    def self.depth(a)
      return 0 unless a.is_a?(Array)
      1 + depth(a[0])
    end

    def self.delta_add_remove(should, current=[], opt=nil)
      # Remove nil entries from array
      should.each(&:compact!) if depth(should) > 1
      delta = { add: should - current, remove: current - should }

      # Some cli properties cannot be updated, thus must be removed first
      return delta if opt == :updates_not_allowed

      # Delete entries from :remove if f1 is an update to an existing command
      delta[:add].each do |id, _|
        if depth(should) == 1
          delta[:remove].delete_if { |f1| [f1] if f1.to_s == id.to_s }
        else
          delta[:remove].delete_if { |f1, f2| [f1, f2] if f1.to_s == id.to_s }
        end
      end
      delta
    end # delta_add_remove

    # Helper to 0-pad a mac address.
    def self.zero_pad_macaddr(mac)
      return nil if mac.nil? || mac.empty?
      o1, o2, o3 = mac.split('.').map { |o| o.to_i(16).to_s(10) }
      sprintf('%04x.%04x.%04x', o1, o2, o3)
    end
  end # class Utils
end   # module Cisco
