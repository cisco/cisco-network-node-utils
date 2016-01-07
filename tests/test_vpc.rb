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
require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/vpc'

include Cisco

# TestVpc - Minitest for Vpc node utility class
class TestVpc < CiscoTestCase
  def setup
    super
    no_feature_vpc
  end

  def teardown
    no_feature_vpc
    super
  end

  def no_feature_vpc
    config('terminal dont-ask ; no feature vpc')
  end

  def n5k6k_platforms?
    /N[56]K/ =~ node.product_id
  end

  def n3k9k_platforms?
    /N[39]K/ =~ node.product_id
  end

  # TESTS

  def test_vpc_create
    @vpc = Vpc.new(100)
    assert(@vpc.domain == 100,
           "VPC domain not set correctly #{@vpc.domain}")
    assert(Vpc.enabled,
           'VPC feature should have been enabled')
    refute(Vpc.domains.empty?,
           'Domain collection should not be empty after create')
  end

  def test_vpc_create_negative
    e = assert_raises(CliError) { Vpc.new(1001) }
    assert_match(/Invalid number.*range/, e.message)
  end

  def test_vpc_destroy
    # create and test again
    @vpc = Vpc.new(100)
    @vpc.destroy
    refute(Vpc.enabled, 'VPC feature should have been disabled')
  end

  def test_auto_recovery
    skip("Test not supported on #{node.product_id}") if
      cmd_ref.lookup('vpc', 'auto_recovery').default_value.nil?
    @vpc = Vpc.new(100)
    default_val = @vpc.auto_recovery
    assert_equal(default_val, @vpc.auto_recovery,
                 "Auto recovery should be #{default_val} by default")
    @vpc.auto_recovery = false
    refute(@vpc.auto_recovery, 'Auto recovery not getting disabled')
    @vpc.auto_recovery = true
    assert(@vpc.auto_recovery, 'Auto recovery not getting set')
  end

  def test_auto_recovery_reload_delay
    @vpc = Vpc.new(100)
    default_value = @vpc.default_auto_recovery_reload_delay
    assert_equal(default_value, @vpc.auto_recovery_reload_delay,
                 "Auto recovery delay should be #{default_value}")
    @vpc.auto_recovery_reload_delay = 300
    assert_equal(300, @vpc.auto_recovery_reload_delay,
                 'Auto recovery delay should be 300')
    # negative high range
    e = assert_raises(CliError) { @vpc.auto_recovery_reload_delay = 3601 }
    assert_match(/Invalid number.*range/, e.message)
  end

  def test_delay_restore
    @vpc = Vpc.new(100)
    default_value = @vpc.default_delay_restore
    assert_equal(default_value, @vpc.delay_restore,
                 "delay_restore should be #{default_value}")
    @vpc.delay_restore = 1000
    assert_equal(1000, @vpc.delay_restore,
                 'delay restore should be 1000')
    # negative high range
    e = assert_raises(CliError) { @vpc.delay_restore = 3601 }
    assert_match(/Invalid number.*range/, e.message)
  end

  def test_delay_restore_interface_vlan
    @vpc = Vpc.new(100)
    default_value = @vpc.default_delay_restore_interface_vlan
    assert_equal(default_value, @vpc.delay_restore_interface_vlan,
                 "delay_restore should be #{default_value}")
    @vpc.delay_restore_interface_vlan = 2000
    assert_equal(2000, @vpc.delay_restore_interface_vlan,
                 'delay restore should be 2000')
    # negative high range
    e = assert_raises(CliError) { @vpc.delay_restore_interface_vlan = 3601 }
    assert_match(/Invalid number.*range/, e.message)
  end

  def test_dual_active_exclude_interface_vlan_bridge_domain
    @vpc = Vpc.new(100)
    default_value =
      @vpc.default_dual_active_exclude_interface_vlan_bridge_domain
    assert_equal(default_value,
                 @vpc.dual_active_exclude_interface_vlan_bridge_domain,
                 "delay_restore should be #{default_value}")
    @vpc.dual_active_exclude_interface_vlan_bridge_domain = '2-20,900'
    assert_equal('2-20,900',
                 @vpc.dual_active_exclude_interface_vlan_bridge_domain,
                 'exclude vlan/bd should be 2-20,900')
    # negative high range
    e = assert_raises(CliError) do
      @vpc.dual_active_exclude_interface_vlan_bridge_domain = '64535'
    end
    assert_match(/Invalid value.*range/, e.message)
  end

  def test_graceful_consistency_check
    @vpc = Vpc.new(100)
    default_val = @vpc.default_graceful_consistency_check
    assert_equal(default_val, @vpc.graceful_consistency_check,
                 "graceful_consistency_check must be #{default_val} by default")
    @vpc.graceful_consistency_check = false
    refute(@vpc.graceful_consistency_check,
           'graceful_consistency_check not getting disabled')
    @vpc.graceful_consistency_check = true
    assert(@vpc.graceful_consistency_check,
           'graceful_consistency_check not getting set')
  end

  def test_layer3_peer_routing
    skip("Test not supported on #{node.product_id}") if
      cmd_ref.lookup('vpc', 'layer3_peer_routing').default_value.nil?
    @vpc = Vpc.new(100)
    # peer gateway must be turned on for this feature
    @vpc.peer_gateway = true
    default_val = @vpc.default_layer3_peer_routing
    assert_equal(default_val, @vpc.layer3_peer_routing,
                 "layer3_peer_routing should be #{default_val} by default")
    @vpc.layer3_peer_routing = true
    assert(@vpc.layer3_peer_routing, 'layer3_peer_routing not getting set')
    @vpc.layer3_peer_routing = false
    refute(@vpc.layer3_peer_routing, 'layer3_peer_routing not getting disabled')
  end

  def test_peer_gateway
    @vpc = Vpc.new(100)
    default_val = @vpc.default_peer_gateway
    assert_equal(default_val, @vpc.peer_gateway,
                 "peer_gateway should be #{default_val} by default")
    @vpc.peer_gateway = true
    assert(@vpc.peer_gateway, 'peer_gateway not getting set')
    @vpc.peer_gateway = false
    refute(@vpc.peer_gateway, 'peer_gateway not getting disabled')
  end

  def test_peer_gateway_exclude_vlan_bridge_domain
    skip("Test not supported on #{node.product_id}") if
      cmd_ref.lookup('vpc', 'peer_gateway_exclude_vlan').default_value.nil?
    @vpc = Vpc.new(100)
    default_val = @vpc.default_peer_gateway_exclude_vlan_bridge_domain
    assert_equal(default_val, @vpc.peer_gateway_exclude_vlan_bridge_domain,
                 "peer_gateway exclude vlan should be #{default_val} default")
    @vpc.peer_gateway_exclude_vlan_bridge_domain = '10-20,400'
    assert_equal('10-20,400', @vpc.peer_gateway_exclude_vlan_bridge_domain,
                 'peer_gateway exclude list not getting set')
    # negative high range
    e = assert_raises(CliError) do
      @vpc.peer_gateway_exclude_vlan_bridge_domain = '64535'
    end
    assert_match(/Invalid value.*range/, e.message)
  end

  def test_role_priority
    @vpc = Vpc.new(100)
    default_value = @vpc.default_role_priority
    assert_equal(default_value, @vpc.role_priority,
                 "Role priority should be #{default_value}")
    @vpc.role_priority = 200
    assert_equal(200, @vpc.role_priority,
                 'Role priority should be 200')
  end

  def test_self_isolation
    skip('Only supported on N7K') unless node.product_id[/N7K/]

    @vpc = Vpc.new(100)
    @vpc.self_isolation = true
    assert_equal(true, @vpc.self_isolation,
                 'Self isolation should have been configured')
  end

  def test_shutdown
    skip('Only supported on N6K,N7K') unless node.product_id[/N[67]K/]
    @vpc = Vpc.new(100)

    @vpc.shutdown = true
    assert(@vpc.shutdown, 'Vpc is not shutdown')

    @vpc.shutdown = false
    refute(@vpc.shutdown, 'Vpc is shutdown')

    @vpc.shutdown = @vpc.default_shutdown
    assert(@vpc.shutdown, 'vpc is not shutdown')
  end

  def test_system_mac
    @vpc = Vpc.new(100)
    default_value = @vpc.default_system_mac
    assert_equal(default_value, @vpc.system_mac,
                 "Default system_mac should be #{default_value}")

    @vpc.system_mac = '1.1.1'
    assert_equal('00:01:00:01:00:01', @vpc.system_mac,
                 'Error: system_mac mismatch')
  end

  def test_system_priority
    @vpc = Vpc.new(100)
    default_value = @vpc.default_system_priority
    assert_equal(default_value, @vpc.system_priority,
                 "System priority should be #{default_value}")
    @vpc.system_priority = 200
    assert_equal(200, @vpc.system_priority,
                 'System priority should be 200')
  end

  def test_track
    @vpc = Vpc.new(100)

    default_value = @vpc.default_track
    assert_equal(default_value, @vpc.track,
                 'default track should be 0')

    @vpc.track = 44
    assert_equal(44, @vpc.track, 'track should be 44')
  end
end
