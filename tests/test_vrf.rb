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
require_relative '../lib/cisco_node_utils/vrf'
require_relative '../lib/cisco_node_utils/vni'

include Cisco

# TestVrf - Minitest for Vrf node utility class
class TestVrf < CiscoTestCase
  VRF_NAME_SIZE = 33

  def setup
    super
    vrfs = Vrf.vrfs
    vrfs.each_value do |vrf|
      next unless vrf.name =~ /^test_vrf/
      config("no vrf context #{vrf.name}")
    end
  end

  def test_vrf_collection_not_empty
    vrfs = Vrf.vrfs
    refute_empty(vrfs, 'VRF collection is empty')
    assert(vrfs.key?('management'), 'VRF management does not exist')
  end

  def test_vrf_create_and_destroy
    v = Vrf.new('test_vrf')
    vrfs = Vrf.vrfs
    assert(vrfs.key?('test_vrf'), 'Error: failed to create vrf test_vrf')

    v.destroy
    vrfs = Vrf.vrfs
    refute(vrfs.key?('test_vrf'), 'Error: failed to destroy vrf test_vrf')
  end

  def test_vrf_name_type_invalid
    assert_raises(TypeError, 'Wrong vrf name type did not raise type error') do
      Vrf.new(1000)
    end
  end

  def test_vrf_name_zero_length
    assert_raises(Cisco::CliError, "Zero length name didn't raise CliError") do
      Vrf.new('')
    end
  end

  def test_vrf_name_too_long
    name = 'a' * VRF_NAME_SIZE
    assert_raises(Cisco::CliError,
                  'vrf name misconfig did not raise CliError') do
      Vrf.new(name)
    end
  end

  def test_vrf_shutdown_valid
    shutdown_states = [true, false]
    v = Vrf.new('test_vrf_shutdown')
    shutdown_states.each do |start|
      shutdown_states.each do |finish|
        v.shutdown = start
        assert_equal(start, v.shutdown, 'start')
        v.shutdown = finish
        assert_equal(finish, v.shutdown, 'finish')
      end
    end
    v.destroy
  end

  def test_vrf_description
    vrf = Vrf.new('test_vrf_description')
    vrf.description = 'tested by minitest'
    assert_equal('tested by minitest', vrf.description,
                 'failed to set description')
    vrf.description = ' '
    assert_empty(vrf.description, 'failed to remove description')
    vrf.destroy
  end

  def test_vrf_vni
    skip('Platform does not support MT-lite') unless Vni.mt_lite_support
    vrf = Vrf.new('test_vrf_vni')
    vrf.vni = 4096
    assert_equal(4096, vrf.vni,
                 "vrf vni should be set to '4096'")
    vrf.vni = vrf.default_vni
    assert_equal(vrf.default_vni, vrf.vni,
                 'vrf vni should be set to default value')
    vrf.destroy
  end
end
