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

  ##################################################
  # Generic Testing Function for Property Matrix
  #
  # EXAMPLE OF USE:
  # - CONTEXT
  #   For "BGP", the context is an ASN number and a VRF name.
  #   The context array contains one sub array per subcontext, containing
  #   an example of each value to test in that subcontext.
  #
  # - NEW_TEST_OBJECT
  #   Must define a methoc called "new_test_object" for the class.
  #   Take a context as input, create a new object of the appropriate type.
  #
  # - TEST VALUES
  #   An array containing one element per test.
  #   Each test contains: [ METHOD_NAME, [VALUE_1, VALUE_2, ...]]
  #   If a test-value is a list, it is sent as multiple parameters to the setter
  #   There is one "special" test value:
  #      :toggle = For boolean properties, this tries both true and false
  #
  # - EXCEPTIONS
  #   An array of expected errors from testing.
  #   Format is:  [ METHOD_NAME, OS_NAME, [CONTEXT], EXPECTED_RESULT]
  #   If there is no matching exception for a test, it is assumed to succeed.
  #   The expected result may be:
  #      :CliError    = This test should fail with CliError
  #      :unsupported = This test should fail with UnsupportedError
  #      :skip        = Override other expectations and skip this test
  #      :success     = Override other expectations and expect success
  #   There are a few short-hand values for matching the context:
  #      :any       = Matches anything
  #      :VRF       = For VRFs, this matches any non-default VRF
  #      :unicast   = For AFs, this matches any unicast AF
  #      :multicast = For AFs, this matches any multicast AF
  #      :ipv4      = For AFs, this matches any IPv4 AF
  #      :ipv6      = For AFs, this matches any IPv6 AF
  #   Add additional shorthands as needed for new properties
  #
  # - GENERATE EXCEPTIONS
  #   As a helper for building the exceptions matrix, pass generate = true
  #   to properties_matrix().  As tests fail, they will generate a line of
  #   ruby code which may be copied into the test exceptions table.
  #   After generating the complete table, resume passing generate = false
  #   to check the exceptions using assert()
  #
  # T_CONTEXT = [
  #   [55],               # ASN -- Only testing one value
  #   %w(default red),    # VRF -- Test VRF as both 'default', and 'red'
  # ]
  #
  # def new_test_object(ctx)
  #   asn, vrf = *ctx     # Break open the context and extract the subunits
  #   create_bgp_vrf(asn, vrf)
  # end
  #
  # T_VALUES = [
  #   [:default_information_originate,  [:toggle]],
  #   [:default_metric,                 [50, false]],
  # ]
  #
  # TEST_EXCEPTIONS = [
  #   #  Test                           OS       [ASN, VRF]     Expected result
  #   [:default_information_originate,  :nexus,  [:any, :any],  :CliError],
  #   [:default_metric,                 :nexus,  [:any, :any],  :CliError],
  # ]
  #
  # def test_properties_matrix
  #   properties_matrix(T_CONTEXT, T_VALUES, TEST_EXCEPTIONS)
  # end

  # rubocop:disable Style/SpaceAroundOperators
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def check_test_exceptions(exns, test_, os_, ctx_)
    ret = []
    amb = []

    exns.each do |test, os, ctx, expect|
      # Check the test and os/platform
      next unless (test == :any || test == test_) &&
                  (os   == :any || os   == os_)

      # Check to see if the context matches
      chk = ctx.zip(ctx_).map do|x, y|
        x == :any ||
        (x == y) ||
        (x == :VRF       && y != 'default')           ||
        (x == :unicast   && (y.include? 'unicast'))   ||
        (x == :multicast && (y.include? 'multicast')) ||
        (x == :ipv4      && (y.include? 'ipv4'))      ||
        (x == :ipv6      && (y.include? 'ipv6'))
      end

      # If context does not match, try next test exception
      next unless chk.uniq == [true] # TODO: does Ruby have "all()" equivelent?

      # Success and Skip override other errors.
      return expect if expect == :success || expect == :skip

      # Record this match and check for ambiguities
      ret.push(expect)
      amb.push([test, os, ctx, expect])
    end

    # The currently defined errors have a hierarchy; "unsupported" is stronger.
    return :unsupported if ret.include?(:unsupported)
    return :success     if ret.empty?

    # In case future errors are defined, lets filter down to only unique values.
    ret.uniq!

    # Make sure there's no ambiguity/overlap in the exceptions.
    # This is required to ensure the exceptions list is order-independent.
    if ret.length > 1
      assert(false, 'TEST ERROR: Exceptions matrix has ambiguous entries! ' \
             "#{amb}")
    end

    # Return the expected test result
    ret[0]
  end

  def properties_matrix(context, values, exns, generate=false)
    # Expand the context into a complete matrix (may be a better way?)
    cartesian_product = context[0].product(*context[1..-1])
    cartesian_product.each do |ctx|
      # For each context, create an object with that context
      test_obj = new_test_object(ctx)

      puts "#{ctx}"

      values.each do |test, test_values|
        # What result do we expect from this test?
        expect = check_test_exceptions(exns, test, platform, ctx)

        puts "#{test}"

        # Gather initial value, default value, and the first test value..
        initial = test_obj.send(test)
        if initial.nil? # unsupported or auto_default: false
          default = nil
          first_value = nil
        else
          default = test_obj.send("default_#{test}")
          first_value = (test_values[0] == :toggle) ? !default : test_values[0]
        end

        if expect == :skip
          # Do nothing..
          puts '         skip'

        elsif expect == :CliError
          puts '         CliError'

          # This set of parameters should produce a CLI error
          assert_raises(Cisco::CliError,
                        "Assert 'cli error' failed for: #{test}, #{ctx}") do
            test_obj.send("#{test}=", first_value)
          end

        elsif expect == :unsupported
          puts '         Unsupported'

          # Getter should return nil when unsupported?  Does not seem to work:
          #    Assert 'nil' inital value failed for:
          #       default_information_originate 55 default ["ipv4", "unicast"].
          #    Expected false to be nil.
          #
          #    Assert 'nil' inital value failed for:
          #       advertise_l2vpn_evpn 55 default ["ipv4", "unicast"].
          #    Expected false to be nil.
          # assert_nil(initial,
          #    "Assert 'nil' inital value failed for: #{test} #{ctx}")

          # Setter should raise UnsupportedError
          assert_raises(Cisco::UnsupportedError,
                        "Assert 'unsupported' failed for: #{test}, #{ctx}") do
            test_obj.send("#{test}=", first_value)
          end

        else

          # Check initial value == default value
          #   Skip this assertion for properties that use auto_default: false
          if generate
            puts "****** default = '#{default}', not #{initial}" if
              !initial.nil? && default != initial
          else
            assert_equal(default, initial,
                         "Initial value failed for: #{test}, #{ctx}"
                        ) unless  initial.nil?
          end

          # Try all the test values in order
          test_values.each do |test_value|
            test_value = (test_value == :toggle) ? !default : test_value

            # Try the test value
            begin
              test_obj.send("#{test}=", test_value)
            rescue Cisco::UnsupportedError
              puts "****** [:#{test}, :#{platform}, #{ctx}, :unsupported]," if
                generate
            rescue Cisco::CliError
              puts "****** [:#{test}, :#{platform}, #{ctx}, :CliError]," if
                generate
            end

            assert_equal(test_value, test_obj.send(test),
                         "Test value failed for: #{test}, #{ctx}") unless
              generate
          end # test_values

          # Set it back to the default
          unless default.nil? || generate
            test_obj.send("#{test}=", default)
            assert_equal(default, test_obj.send(test),
                         "Default assignment failed for: #{test}, #{ctx}")
          end
        end
      end # tests

      # Cleanup
      test_obj.destroy
    end # cartesian_product
  end

  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  # rubocop:enable Style/SpaceAroundOperators
end
