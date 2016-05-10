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
  @skip_unless_supported = 'portchannel_global'
  @@cleaned = false # rubocop:disable Style/ClassVars
  DEFAULT_NAME = 'default'

  def setup
    super
    cleanup unless @@cleaned
    @@cleaned = true # rubocop:disable Style/ClassVars
  end

  def teardown
    cleanup
    super
  end

  def cleanup
    ethernet = node.product_id[/N(3|7|8|9)/] ? '' : 'ethernet'
    config_no_warn "no port-channel load-balance #{ethernet}"
  end

  def n3k_in_n3k_mode?
    return unless /N3/ =~ node.product_id
    mode = config('show system switch-mode')
    # note: an n3k in n9k mode displays: 'system switch-mode n9k'
    patterns = ['system switch-mode n3k',
                'Switch mode configuration is not not applicable']
    mode[Regexp.union(patterns)] ? true : false
  end

  def create_portchannel_global(name=DEFAULT_NAME)
    PortChannelGlobal.new(name)
  end

  def test_hash_distribution
    global = create_portchannel_global
    if validate_property_excluded?('portchannel_global', 'hash_distribution')
      assert_raises(Cisco::UnsupportedError) do
        global.hash_distribution = 'fixed'
      end
      assert_nil(global.hash_distribution)
    else
      global.hash_distribution = 'fixed'
      assert_equal('fixed', global.hash_distribution)
      global.hash_distribution =
        global.default_hash_distribution
      assert_equal(global.default_hash_distribution,
                   global.hash_distribution)
    end
  end

  def test_load_defer
    global = create_portchannel_global
    if validate_property_excluded?('portchannel_global', 'load_defer')
      assert_raises(Cisco::UnsupportedError) do
        global.load_defer = 1000
      end
      assert_nil(global.load_defer)
    else
      global.load_defer = 1000
      assert_equal(1000, global.load_defer)
      global.load_defer =
        global.default_load_defer
      assert_equal(global.default_load_defer,
                   global.load_defer)
    end
  end

  def test_resilient
    global = create_portchannel_global
    if validate_property_excluded?('portchannel_global', 'resilient')
      assert_raises(Cisco::UnsupportedError) { global.resilient = true }
      assert_nil(global.resilient)
      return
    end

    # Verify that hardware supports feature. Unfortunately the current cli
    # only displays a warning and does not raise an error so we have to
    # test for it explicitly.
    cmd = 'port-channel load-balance resilient'
    skip('Skip test: Feature is not supported on this device') if
      config(cmd)[/Resilient Hashing Mode unsupported/]
    global = create_portchannel_global
    # For n3k the default is different from n9k
    if n3k_in_n3k_mode?
      global.resilient = false
      refute(global.resilient)
      global.resilient = global.default_resilient
      assert_equal(global.default_resilient, global.resilient)
    else
      config('no ' + cmd)
      global = create_portchannel_global
      global.resilient = true
      assert(global.resilient)
      global.resilient = global.default_resilient
      assert_equal(global.default_resilient, global.resilient)
    end
  end

  def test_load_balance_no_rotate
    skip('Test not supported on this platform') unless n3k_in_n3k_mode?

    global = create_portchannel_global
    global.send(:port_channel_load_balance=,
                'src-dst', 'ip-only', nil, nil, true, nil, nil)
    assert_equal('src-dst',
                 global.bundle_select)
    assert_equal('ip-only',
                 global.bundle_hash)
    assert_equal(true, global.symmetry)
    global.send(
      :port_channel_load_balance=,
      global.default_bundle_select,
      global.default_bundle_hash,
      nil,
      nil,
      global.default_symmetry,
      nil,
      nil)
    assert_equal(
      global.default_bundle_select,
      global.bundle_select)
    assert_equal(
      global.default_bundle_hash,
      global.bundle_hash)
    assert_equal(
      global.default_symmetry,
      global.symmetry)
  end

  def test_load_balance_sym_concat_rot
    # rubocop:disable Style/MultilineOperationIndentation
    skip('Test not supported on this platform') if n3k_in_n3k_mode? ||
      validate_property_excluded?('portchannel_global', 'symmetry')
    # rubocop:enable Style/MultilineOperationIndentation

    global = create_portchannel_global
    global.send(:port_channel_load_balance=,
                'src-dst', 'ip-l4port', nil, nil, true, true, 4)
    assert_equal('src-dst',
                 global.bundle_select)
    assert_equal('ip-l4port',
                 global.bundle_hash)
    assert_equal(true, global.symmetry)
    assert_equal(true, global.concatenation)
    assert_equal(4, global.rotate)
    global.send(
      :port_channel_load_balance=,
      global.default_bundle_select,
      global.default_bundle_hash,
      nil,
      nil,
      global.default_symmetry,
      global.default_concatenation,
      global.default_rotate)
    assert_equal(
      global.default_bundle_select,
      global.bundle_select)
    assert_equal(
      global.default_bundle_hash,
      global.bundle_hash)
    assert_equal(
      global.default_symmetry,
      global.symmetry)
    assert_equal(
      global.default_concatenation,
      global.concatenation)
    assert_equal(global.default_rotate,
                 global.rotate)
  end

  # assert_hash_poly_crc
  # Depending on the chipset, hash_poly may have have a different
  # default value within the same platform family (this is done to
  # avoid polarization) but there is currently no command available
  # to dynamically determine the default state. As a result the
  # getter simply hard-codes a default value which means it may
  # encounter occasional idempotence issues.
  # For testing purposes this becomes a best-effort test; i.e. we expect the
  # hash_poly test to pass for all asserts except the one that matches the
  # default value for that chipset.
  def assert_hash_poly_crc(exp, actual)
    assert_equal(exp, actual) if exp == actual
  end

  def test_load_balance_hash_poly
    global = create_portchannel_global
    if validate_property_excluded?('portchannel_global', 'hash_poly')
      skip('Test not supported on this platform')
      return
    end

    global.send(:port_channel_load_balance=,
                'src-dst', 'ip-only', 'CRC10c', nil, nil, nil, nil)
    assert_equal('src-dst', global.bundle_select)
    assert_equal('ip-only', global.bundle_hash)
    assert_hash_poly_crc('CRC10c', global.hash_poly)

    global.send(:port_channel_load_balance=,
                'dst', 'mac', 'CRC10a', nil, nil, nil, nil)
    assert_equal('dst', global.bundle_select)
    assert_equal('mac', global.bundle_hash)
    assert_hash_poly_crc('CRC10a', global.hash_poly)

    global.send(:port_channel_load_balance=,
                global.default_bundle_select,
                global.default_bundle_hash,
                'CRC10b', nil, nil, nil, nil)
    assert_equal(global.default_bundle_select, global.bundle_select)
    assert_equal(global.default_bundle_hash, global.bundle_hash)
    assert_hash_poly_crc('CRC10b', global.hash_poly)
  end

  def test_load_balance_asym_rot
    global = create_portchannel_global
    if validate_property_excluded?('portchannel_global', 'asymmetric')
      skip('Test not supported on this platform')
      return
    end

    global.send(:port_channel_load_balance=,
                'src-dst', 'ip-vlan', nil, true, nil, nil, 4)
    assert_equal('src-dst', global.bundle_select)
    assert_equal('ip-vlan', global.bundle_hash)
    assert_equal(true, global.asymmetric)
    assert_equal(4, global.rotate)

    global.send(:port_channel_load_balance=,
                global.default_bundle_select,
                global.default_bundle_hash,
                nil, global.default_asymmetric,
                nil, nil, global.default_rotate)
    assert_equal(global.default_bundle_select, global.bundle_select)
    assert_equal(global.default_bundle_hash, global.bundle_hash)
    assert_equal(global.default_asymmetric, global.asymmetric)
    assert_equal(global.default_rotate, global.rotate)
  end

  def test_load_balance_no_hash_rot
    global = create_portchannel_global
    if validate_property_excluded?('portchannel_global', 'rotate')
      skip('Test not supported on this platform')
      return
    end
    global.send(:port_channel_load_balance=,
                'src-dst', 'ip-vlan', nil, nil, nil, nil, 4)
    assert_equal('src-dst', global.bundle_select)
    assert_equal('ip-vlan', global.bundle_hash)
    assert_equal(4, global.rotate)

    global.send(:port_channel_load_balance=,
                global.default_bundle_select,
                global.default_bundle_hash,
                nil, nil,
                nil, nil, global.default_rotate)
    assert_equal(global.default_bundle_select, global.bundle_select)
    assert_equal(global.default_bundle_hash, global.bundle_hash)
    assert_equal(global.default_rotate, global.rotate)
  end
end
