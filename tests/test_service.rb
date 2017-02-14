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
require_relative '../lib/cisco_node_utils/service'
require 'pp'

include Cisco

# TestService - Minitest for feature Service node Utility class
class TestService < CiscoTestCase
  @skip_unless_supported = 'service'
  ###################
  # Service tests   #
  ###################

  def test_clear_status
    Service.clear_status
    assert_equal(Service.upgraded?, false)
  end

  def test_delete
    Service.delete('nxos.7.0.3.I5.0.231.CSCvb69953.bin')
  end

  def test_delete_boot
    Service.delete_boot
  end

  def test_image_version
    assert_equal(Service.image_version('nxos.7.0.3.I2.1.bin'), '7.0(3)I2(1)')
  end

  def test_upgrade
    sleep 30
    Service.upgrade('nxos.7.0.3.I2.5.bin')
    # Wait for device to reboot
    sleep 250
    assert_equal(Service.upgraded?, true)
  end
end
