#
# NXAPI implementation of Interface OSPF class
#
# March 2015, Alex Hunsberger
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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

require 'ipaddr'
require File.join(File.dirname(__FILE__), 'node')
require File.join(File.dirname(__FILE__), 'interface')
# Interestingly enough, interface OSPF configuration can exist completely
# independent of router OSPF configuration... so we don't need RouterOspf here.

module Cisco
  class InterfaceOspf
    attr_reader :interface, :ospf_name

    @@node = Node.instance

    def initialize(int_name, ospf_name, area, create=true)
      raise TypeError unless int_name.is_a? String
      raise TypeError unless ospf_name.is_a? String
      raise TypeError unless area.is_a? String
      raise ArgumentError unless int_name.length > 0
      raise ArgumentError unless ospf_name.length > 0
      raise ArgumentError unless area.length > 0

      # normalize
      int_name = int_name.downcase
      @interface = Interface.interfaces[int_name]
      raise "interface #{int_name} does not exist" if @interface.nil?

      @ospf_name = ospf_name

      if create
        # enable feature ospf if it isn't
        RouterOspf.enable unless RouterOspf.enabled

        @@node.config_set("interface_ospf", "area", @interface.name,
          "", @ospf_name, area)
      end
    end

    # can't re-use Interface.interfaces because we need to filter based on
    # "ip router ospf <name>", which Interface doesn't retrieve
    def InterfaceOspf.interfaces(ospf_name=nil)
      raise TypeError unless ospf_name.is_a? String or ospf_name.nil?
      ints = {}

      intf_list = @@node.config_get("interface", "all_interfaces")
      return ints if intf_list.nil?
      intf_list.each do |name|
        match = @@node.config_get("interface_ospf", "area", name)
        next if match.nil?
        # should only be a single match under a given interface
        match = match.first
        # ip router ospf <name> area <area>
        ospf = match[0]
        area = match[1]
        next unless ospf_name.nil? or ospf == ospf_name
        int = name.downcase
        ints[int] = InterfaceOspf.new(int, ospf, area, false)
      end
      ints
    end

    def area
      match = @@node.config_get("interface_ospf", "area", @interface.name)
      return nil if match.nil?
      val = match[0][1]
      # Coerce numeric area to the expected dot-decimal format.
      val = IPAddr.new(val.to_i, Socket::AF_INET).to_s unless val.match(/\./)
      val
    end

    def area=(a)
      @@node.config_set("interface_ospf", "area", @interface.name,
        "", @ospf_name, a)
    end

    def destroy
      @@node.config_set("interface_ospf", "area", @interface.name,
        "no", @ospf_name, area)
      # Reset everything else back to default as well:
      self.message_digest = default_message_digest
      message_digest_key_set(default_message_digest_key_id, "", "", "")
      self.cost = default_cost
      self.hello_interval = default_hello_interval
      @@node.config_set("interface_ospf", "dead_interval",
                        @interface.name, "no", "")
      self.passive_interface = default_passive_interface if passive_interface
    end

    def default_message_digest
      @@node.config_get_default("interface_ospf", "message_digest")
    end

    def message_digest
      not @@node.config_get("interface_ospf", "message_digest",
                            @interface.name).nil?
    end

    # interface %s
    #   %s ip ospf authentication message-digest
    def message_digest=(enable)
      @@node.config_set("interface_ospf", "message_digest", @interface.name,
                        enable ? "" : "no")
    end

    def default_message_digest_key_id
      @@node.config_get_default("interface_ospf", "message_digest_key_id")
    end

    def message_digest_key_id
      match = @@node.config_get("interface_ospf", "message_digest_key_id",
                                @interface.name)
      # regex in yaml returns an array result, use .first to get match
      match.nil? ? default_message_digest_key_id : match.first.to_i
    end

    def default_message_digest_algorithm_type
      @@node.config_get_default("interface_ospf",
                                "message_digest_alg_type").to_sym
    end

    def message_digest_algorithm_type
      match = @@node.config_get("interface_ospf", "message_digest_alg_type",
                                @interface.name)
      # regex in yaml returns an array result, use .first to get match
      match.nil? ? default_message_digest_algorithm_type :
        match.first.to_sym
    end

    def default_message_digest_encryption_type
      Encryption.cli_to_symbol(
        @@node.config_get_default("interface_ospf", "message_digest_enc_type"))
    end

    def message_digest_encryption_type
      match = @@node.config_get("interface_ospf", "message_digest_enc_type",
                                @interface.name)
      # regex in yaml returns an array result, use .first to get match
      match.nil? ? default_message_digest_encryption_type :
        Encryption.cli_to_symbol(match.first)
    end

    def message_digest_password
      match = @@node.config_get("interface_ospf", "message_digest_password",
                                @interface.name)
      match.nil? ? nil : match.first
    end

    # interface %s
    #   %s ip ospf message-digest-key %d %s %d %s
    def message_digest_key_set(keyid, algtype, enctype, enc)
      current_keyid = message_digest_key_id
      if keyid == default_message_digest_key_id && current_keyid != keyid
        @@node.config_set("interface_ospf", "message_digest_key_set",
                          @interface.name, "no", current_keyid,
                          "", "", "")
      elsif keyid != default_message_digest_key_id
        raise TypeError unless enc.is_a?(String)
        raise ArgumentError unless enc.length > 0
        enctype = Encryption.symbol_to_cli(enctype)
        @@node.config_set("interface_ospf", "message_digest_key_set",
                          @interface.name, "", keyid, algtype, enctype, enc)
      end
    end

    def cost
      match = @@node.config_get("interface_ospf", "cost", @interface.name)
      # regex in yaml returns an array result, use .first to get match
      match.nil? ? default_cost : match.first.to_i
    end

    def default_cost
      @@node.config_get_default("interface_ospf", "cost")
    end

    # interface %s
    #   ip ospf cost %d
    def cost=(c)
      if c == default_cost
        @@node.config_set("interface_ospf", "cost", @interface.name, "no", "")
      else
        @@node.config_set("interface_ospf", "cost", @interface.name, "", c)
      end
    end

    def hello_interval
      match = @@node.config_get("interface_ospf", "hello_interval",
                                @interface.name)
      # regex in yaml returns an array result, use .first to get match
      match.nil? ? default_hello_interval : match.first.to_i
    end

    def default_hello_interval
      @@node.config_get_default("interface_ospf", "hello_interval")
    end

    # interface %s
    #   ip ospf hello-interval %d
    def hello_interval=(interval)
      @@node.config_set("interface_ospf", "hello_interval",
                        @interface.name, "", interval.to_i)
    end

    def dead_interval
      match = @@node.config_get("interface_ospf", "dead_interval",
                                @interface.name)
      # regex in yaml returns an array result, use .first to get match
      match.nil? ? default_dead_interval : match.first.to_i
    end

    def default_dead_interval
      @@node.config_get_default("interface_ospf", "dead_interval")
    end

    # interface %s
    #   ip ospf dead-interval %d
    def dead_interval=(interval)
      @@node.config_set("interface_ospf", "dead_interval",
                        @interface.name, "", interval.to_i)
    end

    def default_passive_interface
      @@node.config_get_default("interface_ospf", "passive_interface")
    end

    def passive_interface
      not @@node.config_get("interface_ospf", "passive_interface",
                            @interface.name).nil?
    end

    # interface %s
    #   %s ip ospf passive-interface
    def passive_interface=(enable)
      raise TypeError unless enable == true or enable == false
      @@node.config_set("interface_ospf", "passive_interface", @interface.name,
                        enable ? "" : "no")
    end
  end
end
