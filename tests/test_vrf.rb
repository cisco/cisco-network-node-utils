# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/vrf'

include Cisco

# TestVrf - Minitest for Vrf node utility class
class TestVrf < CiscoTestCase
  VRF_NAME_SIZE = 33
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    remove_all_vrfs if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    remove_all_vrfs
    super
  end

  def test_collection_default
    vrfs = Vrf.vrfs
    if platform == :nexus
      refute_empty(vrfs, 'VRF collection is empty')
      assert(vrfs.key?('management'), 'VRF management does not exist')
    else
      assert_empty(vrfs, 'VRF collection is not empty')
    end
  end

  def test_create_and_destroy
    v = Vrf.new('test_vrf')
    vrfs = Vrf.vrfs
    assert(vrfs.key?('test_vrf'), 'Error: failed to create vrf test_vrf')

    v.destroy
    vrfs = Vrf.vrfs
    refute(vrfs.key?('test_vrf'), 'Error: failed to destroy vrf test_vrf')
  end

  def test_name_type_invalid
    assert_raises(TypeError, 'Wrong vrf name type did not raise type error') do
      Vrf.new(1000)
    end
  end

  def test_name_zero_length
    assert_raises(Cisco::CliError, "Zero length name didn't raise CliError") do
      Vrf.new('')
    end
  end

  def test_name_too_long
    name = 'a' * VRF_NAME_SIZE
    assert_raises(Cisco::CliError,
                  'vrf name misconfig did not raise CliError') do
      Vrf.new(name)
    end
  end

  # This helper is needed on some platforms to allow enough time for the
  # 'shutdown' process to complete before 'no shutdown' can be successful.
  def shutdown_with_sleep(obj, val)
    obj.shutdown = val
  rescue CliError => e
    raise unless e.message[/ERROR: Shutdown of VRF .* in progress/]
    sleep 1
    tries ||= 1
    retry unless (tries += 1) > 20
  end

  def test_shutdown
    v = Vrf.new('test_shutdown')
    if validate_property_excluded?('vrf', 'shutdown')
      assert_nil(v.shutdown)
      assert_nil(v.default_shutdown)
      assert_raises(Cisco::UnsupportedError) { v.shutdown = true }
      v.destroy
      return
    end
    v.shutdown = true
    assert(v.shutdown)

    shutdown_with_sleep(v, false)
    refute(v.shutdown)

    v.shutdown = true
    assert(v.shutdown)

    shutdown_with_sleep(v, v.default_shutdown)
    refute(v.shutdown)
    v.destroy
  end

  def test_description
    v = Vrf.new('test_description')
    desc = 'tested by minitest'
    v.description = desc
    assert_equal(desc, v.description)

    desc = v.default_description
    v.description = desc
    assert_equal(desc, v.description)
    v.destroy
  end

  def test_mhost
    v = Vrf.new('test_mhost')
    t_intf = 'Loopback100'
    if validate_property_excluded?('vrf', 'mhost_default_interface')
      assert_nil(v.mhost_ipv4_default_interface)
      assert_nil(v.mhost_ipv6_default_interface)
      assert_raises(Cisco::UnsupportedError) do
        v.mhost_ipv4_default_interface = t_intf
      end
      assert_raises(Cisco::UnsupportedError) do
        v.mhost_ipv6_default_interface = t_intf
      end
      v.destroy
      return
    end
    config("interface #{t_intf}")
    %w(mhost_ipv4_default_interface mhost_ipv6_default_interface).each do |mh|
      df = v.send("default_#{mh}")
      result = v.send("#{mh}")
      assert_equal(df, result, "Test1.1 : #{mh} should be default value")

      v.send("#{mh}=", t_intf)
      result = v.send("#{mh}")
      assert_equal(t_intf, result,
                   "Test2.1 :vrf #{mh} should be set to #{t_intf}")

      df = v.send("default_#{mh}")
      v.send("#{mh}=", "#{df}")
      result = v.send("#{mh}")
      assert_equal(df, result,
                   "Test3.1 :vrf #{mh} should be set to default value")
    end
    config("no interface #{t_intf}")
    v.destroy
  end

  def test_remote_route_filtering
    v = Vrf.new('test_remote_route_filtering')
    if validate_property_excluded?('vrf', 'remote_route_filtering')
      refute(v.remote_route_filtering)
      assert_raises(Cisco::UnsupportedError) do
        v.remote_route_filtering = false
      end
      v.destroy
      return
    end
    assert(v.remote_route_filtering,
           'Test1.1, remote_route_filtering should be default value')
    v.remote_route_filtering = false
    refute(v.remote_route_filtering,
           'Test2.1, remote_route_filtering should be set to false')
    v.remote_route_filtering = v.default_remote_route_filtering
    assert(v.remote_route_filtering,
           'Test3.1, remote_route_filtering should be set to default value')
    v.destroy
  end

  def test_vni
    vrf = Vrf.new('test_vni')
    assert_equal(vrf.default_vni, vrf.vni,
                 'vrf vni should be set to default value')

    vrf.vni = 4096
    assert_equal(4096, vrf.vni,
                 "vrf vni should be set to '4096'")
    vrf.vni = vrf.default_vni
    assert_equal(vrf.default_vni, vrf.vni,
                 'vrf vni should be set to default value')
    vrf.destroy
  rescue RuntimeError => e
    hardware_supports_feature?(e.message)
  end

  def test_route_distinguisher
    skip_nexus_i2_image?
    # Check for compatible linecard (if platform requires it) and set it up
    vxlan_linecard?
    vdc_lc_state('f3')

    v = Vrf.new('green')
    if validate_property_excluded?('vrf', 'route_distinguisher')
      # Must be configured under BGP in IOS XR
      assert_nil(v.route_distinguisher)
      assert_nil(v.default_route_distinguisher)
      assert_raises(Cisco::UnsupportedError) { v.route_distinguisher = 'auto' }
      v.destroy
      return
    end
    v.route_distinguisher = 'auto'
    assert_equal('auto', v.route_distinguisher)

    v.route_distinguisher = '1:1'
    assert_equal('1:1', v.route_distinguisher)

    v.route_distinguisher = '2:3'
    assert_equal('2:3', v.route_distinguisher)

    v.route_distinguisher = v.default_route_distinguisher
    assert_empty(v.route_distinguisher,
                 'v route_distinguisher should *NOT* be configured')
    v.destroy
  end

  def test_vpn_id
    v = Vrf.new('test_vpn_id')
    if validate_property_excluded?('vrf', 'vpn_id')
      assert_nil(v.vpn_id)
      assert_raises(Cisco::UnsupportedError) { v.vpn_id = '1:1' }
      v.destroy
      return
    end
    assert_equal(v.default_vpn_id, v.vpn_id,
                 'Test1.1, vpn_id should be default value')
    %w(1:1 abcdef:12345678).each do |id|
      v.vpn_id = id
      assert_equal(id, v.vpn_id, "Test2.1, vpn_id should be set to #{id}")
    end
    v.vpn_id = v.default_vpn_id
    assert_equal(v.default_vpn_id, v.vpn_id,
                 'Test3.1, vpn_id should be set to default value')
    v.destroy
  end
end
