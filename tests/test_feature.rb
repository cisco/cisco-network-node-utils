# Copyright (c) 2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/feature'
require_relative '../lib/cisco_node_utils/vdc'

include Cisco

# TestFeature - Minitest for feature class
class TestFeature < CiscoTestCase
  @skip_unless_supported = 'feature'

  ###########
  # Helpers #
  ###########

  # VDC helper for features that require a specific linecard.
  # Allows caller to get current state or change it to a new value.
  def vdc_lc_state(type=nil)
    v = Vdc.new('default')
    if type
      # This action may be time consuming, use only if necessary.
      v.limit_resource_module_type = type
    else
      v.limit_resource_module_type
    end
  end

  # feature test helper
  def feature(feat)
    # Get the feature name string from the yaml
    ref = cmd_ref.lookup('feature', feat).to_s[/set_value:.*feature (.*)/]

    if ref
      feat_str = Regexp.last_match[1]
    else
      skip("'feature','#{feat}' is unsupported on this node")
    end

    # Get current state of feature, then disable it
    pre_clean_enabled = Feature.send("#{feat}_enabled?")
    config("no feature #{feat_str}") if pre_clean_enabled
    refute_show_match(
      command: "show running | i #{feat_str}",
      pattern: /^#{feat_str}$/,
      msg:     "#{feat} (#{feat_str}) is still enabled",
    )

    Feature.send("#{feat}_enable")
    # Some features (BGP on n5k!) are slow starters...
    unless Feature.send("#{feat}_enabled?")
      sleep 1
      node.cache_flush
    end
    assert(Feature.send("#{feat}_enabled?"),
           "Feature #{feat} (#{feat_str}) is not enabled")

    # Return testbed to pre-clean state
    config("no feature #{feat_str}") unless pre_clean_enabled
  end

  ###################
  # Feature tests   #
  ###################
  def test_bgp
    feature('bgp')
  end

  def test_fabric_forwarding
    if node.product_id[/N(3)/]
      assert_nil(Feature.fabric_forwarding_enabled?)
      assert_raises(Cisco::UnsupportedError) do
        Feature.fabric_forwarding_enable
      end
      return
    end
    skip('This feature is only supported on 7.0(3)I2 images') unless
      node.os_version[/7.0\(3\)I2\(/]
    feature('fabric_forwarding')
  end

  def test_nv_overlay
    if validate_property_excluded?('feature', 'nv_overlay')
      assert_nil(Feature.nv_overlay_enabled?)
      assert_raises(Cisco::UnsupportedError) { Feature.nv_overlay_enable }
      return
    end
    vxlan_linecard?
    config_no_warn('no feature-set fabricpath')
    Feature.nv_overlay_disable
    sleep 1
    refute_show_match(
      command: "show running | i 'feature nv overlay'",
      pattern: /^feature nv overlay/,
      msg:     'Feature nv overlay is still enabled',
    )

    Feature.nv_overlay_enable
    sleep 1
    assert(Feature.nv_overlay_enabled?,
           'Feature nv overlay is not enabled')
  end

  def test_nv_overlay_evpn
    if node.product_id[/N(3)/]
      assert_nil(Feature.nv_overlay_evpn_enabled?)
      assert_raises(Cisco::UnsupportedError) { Feature.nv_overlay_evpn_enable }
      return
    end
    vdc_current = node.product_id[/N7/] ? vdc_lc_state : nil
    vdc_lc_state('f3') if vdc_current

    # nv_overlay_evpn can't use the 'feature' helper so test it explicitly here
    # Get current state of feature, then disable it
    pre_clean_enabled = Feature.nv_overlay_evpn_enabled?
    feat_str = 'nv overlay evpn'
    config("no #{feat_str}") if pre_clean_enabled

    refute_show_match(
      command: "show running | i #{feat_str}",
      pattern: /^#{feat_str}$/,
      msg:     "(#{feat_str}) is still enabled",
    )
    Feature.nv_overlay_evpn_enable
    assert(Feature.nv_overlay_evpn_enabled?,
           "(#{feat_str}) is not enabled")

    # Return testbed to pre-clean state
    config("no #{feat_str}") unless pre_clean_enabled
    vdc_lc_state(vdc_current) if vdc_current
  end

  def test_ospf
    feature('ospf')
  end

  def test_pim
    feature('pim')
  end

  def test_private_vlan
    feature('private_vlan')
  end

  def test_tacacs
    feature('tacacs')
  end

  def test_vn_segment_vlan_based
    vxlan_linecard?
    Feature.nv_overlay_enable unless node.product_id[/N3/]
    sleep 1
    feature('vn_segment_vlan_based')
  rescue RuntimeError => e
    hardware_supports_feature?(e.message)
  end

  def test_vni
    vxlan_linecard?
    vdc_current = node.product_id[/N7/] ? vdc_lc_state : nil
    vdc_lc_state('f3') if vdc_current

    if node.product_id[/N(5|6)/]
      Feature.nv_overlay_enable
    else
      # vni can't be removed if nv overlay is present
      config_no_warn('no feature nv overlay')
    end

    # Hang observed on n3|9k when show run occurs immediately after removing
    # nv overlay. This minor delay avoids the hang.
    sleep 1
    feature('vni')
    vdc_lc_state(vdc_current) if vdc_current
  rescue RuntimeError => e
    hardware_supports_feature?(e.message)
  end

  def test_vtp
    feature('vtp')
  end

  #####################
  # Feature-set tests #
  #####################

  def test_feature_set_fabric
    if node.product_id[/N(3|8|9)/]
      assert_nil(Feature.fabric_enabled?)
      assert_raises(Cisco::UnsupportedError) { Feature.fabric_enable }
      return
    end
    fs = 'feature-set fabric'
    # Get current state of the feature-set
    feature_set_installed = Feature.fabric_installed?
    feature_enabled = Feature.fabric_enabled?
    vdc_current = node.product_id[/N7/] ? vdc_lc_state : nil

    # clean
    vdc_lc_state('f3') if vdc_current
    config("no #{fs} ; no install #{fs}") if feature_set_installed
    refute_show_match(
      command: "show running | i '^install #{fs}$'",
      pattern: /^install #{fs}$/,
      msg:     "(#{fs}) is still configured",
    )

    Feature.fabric_enable
    assert(Feature.fabric_enabled?, "(#{fs}) is not enabled")

    # Return testbed to pre-clean state
    config("no #{fs}") unless feature_enabled
    config("no install #{fs}") unless feature_set_installed
    vdc_lc_state(vdc_current) if vdc_current
  end

  def test_feature_set_fex
    if validate_property_excluded?('feature', 'fex')
      assert_nil(Feature.fex_enabled?)
      assert_raises(Cisco::UnsupportedError) { Feature.fex_enable }
      return
    end
    fs = 'feature-set fex'

    # clean
    config("no #{fs} ; no install #{fs}") if Feature.fex_installed?
    refute_show_match(
      command: "show running | i '^install #{fs}$'",
      pattern: /^install #{fs}$/,
      msg:     "(#{fs}) is still configured",
    )

    Feature.fex_enable
    assert(Feature.fex_enabled?, "(#{fs}) is not enabled")
  end
end
