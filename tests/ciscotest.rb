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

# CiscoTestCase - base class for all node utility minitests
class CiscoTestCase < TestCase
  # rubocop:disable Style/ClassVars
  @@node = nil
  @@interfaces = nil
  @@interfaces_id = nil
  # rubocop:enable Style/ClassVars

  # The feature (lib/cisco_node_utils/cmd_ref/<feature>.yaml) that this
  # test case is associated with, if applicable.
  # If the YAML file excludes this entire feature for this platform
  # (top-level _exclude statement, not individual attributes), then
  # all tests in this test case will be skipped.
  @skip_unless_supported = nil

  class << self
    attr_accessor :skip_unless_supported
  end

  def self.runnable_methods
    return super if skip_unless_supported.nil?
    return super if node.cmd_ref.supports?(skip_unless_supported)
    # If the entire feature under test is unsupported,
    # undefine the setup/teardown methods (if any) and skip the whole test case
    remove_method :setup if instance_methods(false).include?(:setup)
    remove_method :teardown if instance_methods(false).include?(:teardown)
    [:all_skipped]
  end

  def all_skipped
    skip("Skipping #{self.class}; feature " \
         "'#{self.class.skip_unless_supported}' is unsupported on this node")
  end

  def self.node
    unless @@node
      # rubocop:disable Style/ClassVars
      @@node = Node.instance(address, username, password)
      # rubocop:enable Style/ClassVars
      @@node.cache_enable = true
      @@node.cache_auto = true
      # Record the platform we're running on
      puts "\nNode under test:"
      puts "  - name  - #{@@node.host_name}"
      puts "  - type  - #{@@node.product_id}"
      puts "  - image - #{@@node.system}\n\n"
    end
    @@node
  rescue Cisco::AuthenticationFailed
    abort "Unauthorized to connect as #{username}:#{password}@#{address}"
  rescue Cisco::ClientError, TypeError, ArgumentError => e
    abort "Error in establishing connection: #{e}"
  end

  def node
    self.class.node
  end

  def setup
    super
    node
  end

  def cmd_ref
    node.cmd_ref
  end

  def self.platform
    node.client.platform
  end

  def platform
    self.class.platform
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
    int_ip == convert_dns_name(address.split(':')[0])
  end

  # Some NXOS hardware is not capable of supporting certain features even
  # though the platform family in general includes support. In these cases
  # the NU feature setter will raise a RuntimeError.
  def hardware_supports_feature?(message)
    patterns = ['Hardware is not capable of supporting',
                'is unsupported on this node',
               ]
    skip('Skip test: Feature is unsupported on this device') if
      message[Regexp.union(patterns)]
    flunk(message)
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
        id = interface.split('ethernet')[1]
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

  # Remove all configurations from an interface.
  def interface_cleanup(intf_name)
    cfg = get_interface_cleanup_config(intf_name)
    config(*cfg)
  end

  # Returns an array of commands to remove all configurations from
  # an interface.
  def get_interface_cleanup_config(intf_name)
    if platform == :ios_xr
      ["no interface #{intf_name}", "interface #{intf_name} shutdown"]
    else
      ["default interface #{intf_name}"]
    end
  end
end
