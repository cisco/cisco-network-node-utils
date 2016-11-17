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
require_relative '../lib/cisco_node_utils/bridge_domain'
require_relative '../lib/cisco_node_utils/interface'
require_relative '../lib/cisco_node_utils/node'
require_relative '../lib/cisco_node_utils/platform'
require_relative '../lib/cisco_node_utils/vlan'

include Cisco

# CiscoTestCase - base class for all node utility minitests
class CiscoTestCase < TestCase
  # rubocop:disable Style/ClassVars
  @@node = nil
  @@interfaces = nil
  @@interfaces_id = nil
  @@testcases = []
  @@testcase_teardowns = 0

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
    @@testcases = super
    return super if skip_unless_supported.nil?
    return super if node.cmd_ref.supports?(skip_unless_supported)
    # If the entire feature under test is unsupported,
    # undefine the setup/teardown methods (if any) and skip the whole test case
    remove_method :setup if instance_methods(false).include?(:setup)
    remove_method :teardown if instance_methods(false).include?(:teardown)
    [:all_skipped]
  end

  def first_or_last_teardown
    # Return true if this is the first or last teardown call.
    # This hack is needed to prevent excessive post-test cleanups from
    # occurring: e.g. a non-F3 N7k test class may require an expensive setup
    # and teardown to enable/disable vdc settings; ideally this vdc setup
    # would occur prior to the first test and vdc teardown only after the
    # final test. Checks for first test case because we have to handle the
    # -n option, which filters the list of runnable testcases.
    # Note that Minitest.after_run is not a solution for this problem.
    @@testcase_teardowns += 1
    (@@testcase_teardowns == 1) || (@@testcase_teardowns == @@testcases.size)
  end
  # rubocop:enable Style/ClassVars

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
      result = super(warn_match, *args, 'commit')
    else
      result = super
    end
    node.cache_flush
    result
  end

  # Check exception and only fail if it does not contain message
  def check_and_raise_error(exception, message)
    fail exception unless exception.message.include?(message)
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

  def incompatible_interface?(msg)
    patterns = ['switchport_mode is not supported on this interface',
                'Configuration does not match the port capability']
    assert_match(Regexp.union(patterns), msg,
                 'Msg does not match known incompatibility messages')
  end

  def validate_property_excluded?(feature, property)
    !node.cmd_ref.supports?(feature, property)
  end

  def skip_nexus_i2_image?
    skip("This property is not supported on Nexus 'I2' images") if
      Utils.nexus_i2_image
  end

  def system_image
    @image ||= Platform.system_image
  end

  def skip_legacy_defect?(pattern, msg)
    msg = "Defect in legacy image: [#{msg}]"
    skip(msg) if system_image.match(Regexp.new(pattern))
  end

  def interfaces
    unless @@interfaces
      # Build the platform_info, used for interface lookup
      # rubocop:disable Style/ClassVars
      @@interfaces = []
      Interface.interfaces.each do |int, obj|
        next unless int[%r{ethernet[\d/]+$}] # exclude dot1q & non-eth
        next if address_match?(obj.ipv4_address)
        @@interfaces << int
      end
      # rubocop:enable Style/ClassVars
    end
    skip "No suitable interfaces found on #{node} for this test" if
      @@interfaces.empty?
    @@interfaces
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
    return unless /N7/ =~ node.product_id
    BridgeDomain.bds.each do |_bd, obj|
      obj.destroy
    end
    config 'system bridge-domain none'
  end

  def remove_all_svis
    Interface.interfaces(:vlan).each do |svi, obj|
      next if svi == 'vlan1'
      obj.destroy
    end
  end

  # This testcase will remove all the vlans existing in the system
  # specifically in cleanup for minitests
  def remove_all_vlans
    remove_all_bridge_domains
    remove_all_svis
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
      # TBD: Remove vrf workaround below after CSCuz56697 is resolved
      config 'vrf context ' + vrf if node.product_id[/N9K.*-F/]
      obj.destroy
    end
  end

  # Remove all configurations from an interface.
  def interface_cleanup(intf_name)
    cfg = get_interface_cleanup_config(intf_name)
    config(*cfg)
  end

  # TBD: -- The following methods are a WIP --
  #
  # def find_compatible_intf(feature, opt=:raise_skip)
  #   # Some platforms require specific linecards before allowing a feature to
  #   # be enabled. This method will find a compatible interface or optionally
  #   # raise a skip.
  #   # TBD: This wants to become a common "compatible interface" checker to
  #   # eventually replace all of the single-use methods.
  #   intf = compatible_intf(feature)
  #   if intf.nil? && opt[/raise_skip/]
  #     skip("Unable to find compatible interface for 'feature #{feature}'")
  #   end
  #   intf
  # end

  # def compatible_intf(feature)
  #   # The feat hash contains module restrictions for a given feature.
  #   #  :mods - (optional) The module ids used in the 'limit-resource' config
  #   #  :pids - A regex pattern for the line module product IDs (ref: 'sh mod')
  #   feat = {}
  #   if node.product_id[/N7K/]
  #     feat = {
  #       # nv overlay raises error unless solely F3
  #       'nv overlay' => { mods: 'f3', pids: 'N7[K7]-F3' }
  #     }
  #   end
  #   patterns = feat[feature]
  #   return interfaces[0] if patterns.nil? #  No restrictions for this platform

  #   # Check if module is present and usable; i.e. 'ok'
  #   pids = patterns[:pids]
  #   sh_mod_string = @device.cmd("show mod | i '^[0-9]+.*#{pids}.*ok'")
  #   sh_mod = sh_mod_string[/^(\d+)\s.*#{pids}/]
  #   slot = sh_mod.nil? ? nil : Regexp.last_match[1]
  #   return nil if slot.nil?
  #   intf = "ethernet#{slot}/1"

  #   # Check/Set VDC config. VDC platforms restrict module usage per vdc.
  #   mods = patterns[:mods]
  #   return intf if mods.nil? || !node.product_id[/N7K/]
  #   vdc = Vdc.new(Vdc.default_vdc_name)
  #   unless mods == vdc.limit_resource_module_type
  #     # Update the allowed module types in this vdc
  #     vdc.limit_resource_module_type = mods
  #   end

  #   # Return the first interface found in 'allocate interface' config, or nil
  #   vdc.allocate_interface[%r{Ethernet#{slot}\/(\d+)}]
  # end

  def vdc_limit_f3_no_intf_needed(action=:set)
    # This is a special-use method for N7Ks that don't have a physical F3.
    #  1) There are some features that refuse to load unless the VDC is
    #     limited to F3 only, but they will actually load if the config is
    #     present, despite the fact that there are no physical F3s.
    #  2) We have some tests that need these features but don't need interfaces.
    #
    # action = :set (enable limit F3 config), :clear (default limit config)
    #
    # The limit config should be removed after testing if the device does not
    # have an actual F3.
    return unless node.product_id[/N7K/]
    vdc = Vdc.new(Vdc.default_vdc_name)
    case action
    when :set
      return if vdc.limit_resource_module_type == 'f3'
      vdc.limit_resource_module_type = 'f3'

    when :clear
      # Remove the config if there are no physical F3 cards
      pids = 'N7[K7]-F3'
      sh_mod_string = @device.cmd("show mod | i '^[0-9]+.*#{pids}'")
      sh_mod = sh_mod_string[/^(\d+)\s.*#{pids}/]
      if sh_mod.nil?
        # It's safe to remove the config
        vdc.limit_resource_module_type = ''
      end
    end
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
    #   '2   4  Nexus 4xQSFP Ethernet Module  N6K-C6001-M4Q ok'
    if node.product_id[/N(5|6)K/]
      sh_mod_string = @device.cmd("sh mod | i '^[0-9]+.*N[56]K-C[56]'")
      sh_mod = sh_mod_string[/^(\d+)\s.*N[56]K-C(56|600[14])/]
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
      node.product_id[/N3K|N9K.*-F|N9K/]
    unless context == 'bash' || context == 'guestshell'
      fail "Context must be either 'bash' or 'guestshell'"
    end
    config("run #{context} #{command}")
  end

  def backup_resolv_file(context='bash')
    # Configuration bleeding is only a problem on some platforms, so
    # only backup the resolv.conf file on required plaforms.
    return unless node.product_id[/N3K|N9K.*-F|N9K/]
    time_stamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    backup_filename = "/tmp/resolv.conf.#{time_stamp}"
    shell_command("cp /etc/resolv.conf #{backup_filename}", context)
    backup_filename
  end

  def restore_resolv_file(filename, context='bash')
    return unless node.product_id[/N3K|N9K.*-F|N9K/]
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

  # Helper method to massage node.product_id into a short but
  # meaningful tag to represent the product_type.
  def product_tag
    @product_id ||= node.product_id
    case @product_id
    when /N3/
      tag = 'n3k'
    when /N5/
      tag = 'n5k'
    when /N6/
      tag = 'n6k'
    when /N7/
      tag = 'n7k'
    when /N9/
      tag = Utils.image_version?(/7.0.3.F/) ? 'n9k-f' : 'n9k'
    else
      fail "Unrecognized product_id: #{@product_id}"
    end
    tag
  end
end
