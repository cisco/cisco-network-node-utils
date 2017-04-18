# Copyright (c) 2016-2017 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/upgrade'

include Cisco

# TestUpgrade - Minitest for router Upgrade node Utility class
class TestUpgrade < CiscoTestCase
  @skip_unless_supported = 'upgrade'

  def preconfig_upgrade_info
    path = File.expand_path('../upgrade_info.yaml', __FILE__)
    skip('Cannot find tests/upgrade_info.yaml') unless File.file?(path)
    info = YAML.load(File.read(path))
    valid_info?(info)
    info
  end

  def valid_info?(info)
    skip('tests/upgrade_info.yaml file is empty') unless info
    msg = 'Missing key in tests/upgrade_info.yaml'
    %w(install_image install_uri).each do |key|
      skip("#{msg}: #{key}") if info[key].nil?
    end
  end

  ###################
  # Upgrade tests   #
  ###################

  def test_clear_status
    Upgrade.clear_status
    refute(Upgrade.upgraded?)
  end

  def test_delete
    config('show version > bootflash:foobar')
    Upgrade.delete('foobar')
    assert_raises(CliError) do
      Upgrade.delete('foobar')
    end
  end

  def test_delete_negative
    assert_raises(CliError) do
      # Delete a file that doesn't exist
      Upgrade.delete('foobar')
    end
    assert_raises(CliError) do
      # Delete a file that doesn't exist
      Upgrade.delete('foobar', 'logflash:')
    end
  end

  # def test_delete_boot
  #   Upgrade.delete_boot
  # end

  def test_image_version
    version = Upgrade.image_version
    assert_match(/^\d.\d\(\d\)\S+\(\S+\)$/, version)
  end

  def test_box_online
    assert(Upgrade.box_online?)
  end

  def test_upgrade
    image_info = preconfig_upgrade_info
    Upgrade.upgrade(image_info['install_image'], image_info['install_uri'])
    # Wait 15 seconds for device to start rebooting
    # TODO : Consider getting the sleep value dynamically
    sleep 15
    begin
      assert(Upgrade.upgraded?)
    rescue
      tries ||= 1
      retry unless (tries += 1) > 5
      raise
    end
  end

  def test_upgrade_boot_image
    preconfig_upgrade_info
    image_uri = node.config_get('show_version', 'system_image')
    image = image_uri.split('/')[-1]
    uri = image_uri.split('/')[0]
    skip('Boot image not on bootflash:') unless uri == 'bootflash:'
    Upgrade.upgrade(image, uri)
    assert(Upgrade.upgraded?)
  end
end
