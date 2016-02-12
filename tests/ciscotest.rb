# Copyright (c) 2013-2016 Cisco and/or its affiliates.
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
require 'resolv'
require_relative 'basetest'
require_relative 'platform_info'
require_relative '../lib/cisco_node_utils/interface'
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
      puts "  - image - #{@@node.system}\n\n"
    end
    @@node
  rescue CiscoNxapi::HTTPUnauthorized
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

  def config(*args)
    result = super
    node.cache_flush
    result
  end

  def ip_address?(ip)
    return IPAddr.new(ip).ipv4?
  rescue IPAddr::InvalidAddressError
    false
  end

  def convert_dns_name(ip)
    ip_address?(ip) ? ip : Resolv.getaddress(ip)
  rescue Resolv::ResolvError
    raise "Unable to resolve name #{ip}. Use static ip to connect instead!"
  end

  def address_match?(int_ip)
    # Compare the interface address with the current session address.
    # and return true if they match.
    return false if int_ip.nil?
    int_ip == convert_dns_name(address)
  end

  def interfaces
    unless @@interfaces
      # Build the platform_info, used for interface lookup
      # rubocop:disable Style/ClassVars
      @@interfaces = []
      Interface.interfaces.each do |int, obj|
        next unless /ethernet/.match(int)
        next if address_match?(obj.ipv4_address)
        @@interfaces << int
      end
      # rubocop:enable Style/ClassVars
    end
    abort "No suitable interfaces found on #{node} for this test" if
      @@interfaces.empty?
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

  # Remove all router bgps.
  def remove_all_bgps
    require_relative '../lib/cisco_node_utils/bgp'
    RouterBgp.routers.each do |_asn, vrfs|
      vrfs.each do |vrf, obj|
        if vrf == 'default'
          obj.destroy
          break
        end
      end
    end
  end

  # Remove all user vrfs.
  def remove_all_vrfs
    require_relative '../lib/cisco_node_utils/vrf'
    Vrf.vrfs.each do |vrf, obj|
      next if vrf[/management/]
      obj.destroy
    end
  end
end
