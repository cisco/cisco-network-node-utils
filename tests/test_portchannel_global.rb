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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/portchannel_global'

# TestX__CLASS_NAME__X - Minitest for X__CLASS_NAME__X node utility class
class TestPortchannelGlobal < CiscoTestCase
  # TESTS

  DEFAULT_NAME = 'default'

  def setup
    super
    config 'no port-channel load-balance' unless n6k_platform?
    config 'no port-channel load-balance ethernet' unless
    n9k_platform? || n7k_platform?
  end

  def teardown
    config 'no port-channel load-balance' unless n6k_platform?
    config 'no port-channel load-balance ethernet' unless
    n9k_platform? || n7k_platform?
    super
  end

  def n3k_in_n3k_mode?
    return unless /N3/ =~ node.product_id
    mode = config('show system switch-mode')
    # note: an n3k in n9k mode displays: 'system switch-mode n9k'
    patterns = ['system switch-mode n3k',
                'Switch mode configuration is not not applicable']
    mode[Regexp.union(patterns)] ? true : false
  end

  def n7k_platform?
    /N7/ =~ node.product_id
  end

  def n9k_platform?
    /N(3|9)/ =~ node.product_id
  end

  def n6k_platform?
    /N(5|6)/ =~ node.product_id
  end

  def create_portchannel_global(name=DEFAULT_NAME)
    PortChannelGlobal.new(name)
  end

  def test_get_hash_distribution
    skip('Platform does not support this property') if n6k_platform? ||
                                                       n9k_platform?
    @global = create_portchannel_global
    @global.hash_distribution = 'fixed'
    assert_equal('fixed', @global.hash_distribution)
    @global.hash_distribution =
      @global.default_hash_distribution
    assert_equal(@global.default_hash_distribution,
                 @global.hash_distribution)
  end

  def test_get_set_load_defer
    skip('Platform does not support this property') if n6k_platform? ||
                                                       n9k_platform?
    @global = create_portchannel_global
    @global.load_defer = 1000
    assert_equal(1000, @global.load_defer)
    @global.load_defer =
      @global.default_load_defer
    assert_equal(@global.default_load_defer,
                 @global.load_defer)
  end

  def test_get_set_resilient
    skip('Platform does not support this property') if n6k_platform? ||
                                                       n7k_platform?
    @global = create_portchannel_global
    @global.resilient = true
    assert_equal(true, @global.resilient)
    @global.resilient = @global.default_resilient
    assert_equal(@global.default_resilient, @global.resilient)
  end

  def test_get_set_port_channel_load_balance_sym_concat_rot
    skip('Platform does not support this property') if
      n6k_platform? || n7k_platform? || n3k_in_n3k_mode?
    @global = create_portchannel_global
    @global.send(:port_channel_load_balance=,
                 'src-dst', 'ip-l4port', nil, nil, true, true, 4)
    assert_equal('src-dst',
                 @global.bundle_select)
    assert_equal('ip-l4port',
                 @global.bundle_hash)
    assert_equal(true, @global.symmetry)
    assert_equal(true, @global.concatenation)
    assert_equal(4, @global.rotate)
    @global.send(
      :port_channel_load_balance=,
      @global.default_bundle_select,
      @global.default_bundle_hash,
      nil,
      nil,
      @global.default_symmetry,
      @global.default_concatenation,
      @global.default_rotate)
    assert_equal(
      @global.default_bundle_select,
      @global.bundle_select)
    assert_equal(
      @global.default_bundle_hash,
      @global.bundle_hash)
    assert_equal(
      @global.default_symmetry,
      @global.symmetry)
    assert_equal(
      @global.default_concatenation,
      @global.concatenation)
    assert_equal(@global.default_rotate,
                 @global.rotate)
  end

  def test_get_set_port_channel_load_balance_hash_poly
    skip('Platform does not support this property') if n7k_platform? ||
                                                       n9k_platform?
    @global = create_portchannel_global
    @global.send(:port_channel_load_balance=,
                 'src-dst', 'ip-only', 'CRC10c', nil, nil, nil, nil)
    assert_equal('src-dst',
                 @global.bundle_select)
    assert_equal('ip-only',
                 @global.bundle_hash)
    assert_equal('CRC10c', @global.hash_poly)
    @global.send(:port_channel_load_balance=,
                 'dst', 'mac', 'CRC10a', nil, nil, nil, nil)
    assert_equal('dst',
                 @global.bundle_select)
    assert_equal('mac',
                 @global.bundle_hash)
    assert_equal('CRC10a', @global.hash_poly)
    @global.send(
      :port_channel_load_balance=,
      @global.default_bundle_select,
      @global.default_bundle_hash,
      @global.default_hash_poly,
      nil, nil, nil, nil)
    assert_equal(
      @global.default_bundle_select,
      @global.bundle_select)
    assert_equal(
      @global.default_bundle_hash,
      @global.bundle_hash)
    assert_equal(@global.default_hash_poly,
                 @global.hash_poly)
  end

  def test_get_set_port_channel_load_balance_asym_rot
    skip('Platform does not support this property') if n6k_platform? ||
                                                       n9k_platform?
    @global = create_portchannel_global
    @global.send(:port_channel_load_balance=,
                 'src-dst', 'ip-vlan', nil, true, nil, nil, 4)
    assert_equal('src-dst',
                 @global.bundle_select)
    assert_equal('ip-vlan',
                 @global.bundle_hash)
    assert_equal(true, @global.asymmetric)
    assert_equal(4, @global.rotate)
    @global.send(
      :port_channel_load_balance=,
      @global.default_bundle_select,
      @global.default_bundle_hash,
      nil,
      @global.default_asymmetric,
      nil,
      nil,
      @global.default_rotate)
    assert_equal(
      @global.default_bundle_select,
      @global.bundle_select)
    assert_equal(
      @global.default_bundle_hash,
      @global.bundle_hash)
    assert_equal(
      @global.default_asymmetric,
      @global.asymmetric)
    assert_equal(@global.default_rotate,
                 @global.rotate)
  end
end
