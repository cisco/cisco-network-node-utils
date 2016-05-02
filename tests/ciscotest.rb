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
require_relative '../lib/cisco_node_utils/vlan'
require_relative '../lib/cisco_node_utils/bridge_domain'

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
      @@node = Node.instance
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

  def config_and_warn_on_match(warn_match, *args)
    if node.client.platform == :ios_xr
      result = super(warn_match, *args, 'commit best-effort')
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

  def validate_property_excluded?(feature, property)
    !node.cmd_ref.supports?(feature, property)
  end

  def skip_nexus_i2_image?
    skip("This property is not supported on Nexus 'I2' images") if
      Utils.nexus_i2_image
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
    skip "No suitable interfaces found on #{node} for this test" if
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

  # Remove all router ospfs.
  def remove_all_ospfs
    require_relative '../lib/cisco_node_utils/router_ospf'
    RouterOspf.routers.each do |_, obj|
      obj.destroy
    end
  end

  # This testcase will remove all the bds existing in the system
  # specifically in cleanup for minitests
  def remove_all_bridge_domains
    config 'system bridge-domain none' if /N7/ =~ node.product_id
    BridgeDomain.bds.each do |_bd, obj|
      obj.destroy
    end
  end

  # This testcase will remove all the vlans existing in the system
  # specifically in cleanup for minitests
  def remove_all_vlans
    remove_all_bridge_domains
    Vlan.vlans.each do |vlan, obj|
      # skip reserved vlan
      next if vlan == '1'
      next if node.product_id[/N5K|N6K|N7K/] && (1002..1005).include?(vlan.to_i)
      obj.destroy
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

  # setup fabricpath env if possible and populate the interfaces array
  # otherwise cause a global skip
  def fabricpath_testenv_setup
    return unless node.product_id[/N7K/]
    intf_array = Feature.compatible_interfaces('fabricpath')
    vdc = Vdc.new(Vdc.default_vdc_name)
    save_lr = vdc.limit_resource_module_type
    fabricpath_lr = node.config_get('fabricpath', 'supported_modules')
    if intf_array.empty? || save_lr != fabricpath_lr
      # try getting the required modules into the default vdc
      vdc.limit_resource_module_type = fabricpath_lr
      intf_array = Feature.compatible_interfaces('fabricpath')
    end
    if intf_array.empty?
      vdc.limit_resource_module_type = save_lr
      skip('FabricPath compatible interfaces not found in this switch')
    else
      # rubocop:disable Style/ClassVars
      @@interfaces = intf_array
      # rubocop:enable Style/ClassVars
    end
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

  def mt_full_interface?
    # MT-full tests require a specific linecard; either because they need a
    # compatible interface or simply to enable the features. Either way
    # we will provide an appropriate interface name if the linecard is present.
    # Example 'show mod' output to match against:
    #   '9  12  10/40 Gbps Ethernet Module  N7K-F312FQ-25 ok'
    #   '9  12  10/40 Gbps Ethernet Module  N77-F312FQ-25 ok'
    sh_mod_string = @device.cmd("sh mod | i '^[0-9]+.*N7[7K]-F3'")
    sh_mod = sh_mod_string[/^(\d+)\s.*N7[7K]-F3.*ok/]
    slot = sh_mod.nil? ? nil : Regexp.last_match[1]
    skip('Unable to find compatible interface in chassis') if slot.nil?

    "ethernet#{slot}/1"
  end

  def vxlan_linecard?
    # n5,6,7k tests require a specific linecard; either because they need a
    # compatible interface or simply to enable vxlan.
    # Example 'show mod' output to match against:
    #   '9  12  10/40 Gbps Ethernet Module  N7K-F312FQ-25 ok'
    #   '9  12  10/40 Gbps Ethernet Module  N77-F312FQ-25 ok'
    #   '2   6  Nexus 6xQSFP Ethernet Module  N5K-C5672UP-M6Q ok'
    #   '2   6  Nexus xxQSFP Ethernet Module  N6K-C6004-96Q/EF ok'
    if node.product_id[/N(5|6)K/]
      sh_mod_string = @device.cmd("sh mod | i '^[0-9]+.*N[56]K-C[56]'")
      sh_mod = sh_mod_string[/^(\d+)\s.*N[56]K-C(56|6004)/]
      skip('Unable to find compatible interface in chassis') if sh_mod.nil?
    elsif node.product_id[/N7K/]
      mt_full_interface?
    else
      return
    end
  end

  # Wrapper api that can be used to execute bash shell or guestshell
  # commands.
  # Returns the output of the command.
  def shell_command(command, context='bash')
    fail "shell_command api not supported on #{node.product_id}" unless
      node.product_id[/N3K|N8K|N9K/]
    unless context == 'bash' || context == 'guestshell'
      fail "Context must be either 'bash' or 'guestshell'"
    end
    config("run #{context} #{command}")
  end

  def backup_resolv_file(context='bash')
    # Configuration bleeding is only a problem on some platforms, so
    # only backup the resolv.conf file on required plaforms.
    return unless node.product_id[/N3K|N8K|N9K/]
    time_stamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    backup_filename = "/tmp/resolv.conf.#{time_stamp}"
    shell_command("cp /etc/resolv.conf #{backup_filename}", context)
    backup_filename
  end

  def restore_resolv_file(filename, context='bash')
    return unless node.product_id[/N3K|N8K|N9K/]
    shell_command("sudo cp #{filename} /etc/resolv.conf", context)
    shell_command("rm #{filename}", context)
  end

  # VDC helper for features that require a specific linecard.
  # Allows caller to get current state or change it to a new value.
  def vdc_lc_state(type=nil)
    return unless node.product_id[/N7/]
    vxlan_linecard? if type && type[/F3/i]
    v = Vdc.new('default')
    if type
      # This action may be time consuming, use only if necessary.
      v.limit_resource_module_type = type
    else
      v.limit_resource_module_type
    end
  end
end
