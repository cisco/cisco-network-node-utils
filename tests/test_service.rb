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
require_relative '../lib/cisco_node_utils/service'

include Cisco

# TestService - Minitest for feature Service node Utility class
class TestService < CiscoTestCase
  @skip_unless_supported = 'service'

  def preconfig_service_info
    path = File.expand_path('../service_info.yaml', __FILE__)
    skip('Cannot find tests/service_info.yaml') unless File.file?(path)
    info = YAML.load(File.read(path))
    valid_info?(info)
    info
  end

  def valid_info?(info)
    skip('tests/service_info.yaml file is empty') unless info
    msg = 'Missing key in tests/service_info.yaml'
    %w(install_image install_media).each do |key|
      skip("#{msg}: #{key}") if info[key].nil?
    end
  end

  ###################
  # Service tests   #
  ###################

  def test_clear_status
    Service.clear_status
    refute(Service.upgraded?)
  end

  def test_delete
    shell_command('touch /bootflash/foobar')
    Service.delete('foobar')
    assert_raises(CliError) do
      Service.delete('foobar')
    end
  end

  def test_delete_negative
    assert_raises(CliError) do
      # Delete a file that doesn't exist
      Service.delete('foobar')
    end
    assert_raises(CliError) do
      # Delete a file that doesn't exist
      Service.delete('foobar', 'logflash:')
    end
  end

  # def test_delete_boot
  #   Service.delete_boot
  # end

  def test_image_version
    version = Service.image_version
    assert_match(/^\d.\d\(\d\)\S+\(\S+\)$/, version)
  end

  def test_upgrade
    image_info = preconfig_service_info
    Service.upgrade(image_info['install_image'], image_info['install_media'])
    # Wait 15 seconds for device to start rebooting
    # TODO : Consider getting the sleep value dynamically
    sleep 15
    begin
      assert(Service.upgraded?)
    rescue
      tries ||= 1
      retry unless (tries += 1) > 3
      raise
    end
  end

  def test_upgrade_boot_image
    image_uri = node.config_get('show_version', 'system_image')
    image = image_uri.split('/')[-1]
    media = image_uri.split('/')[0]
    skip('Boot image not on bootflash:') unless media == 'bootflash:'
    Service.upgrade(image, media)
    assert(Service.upgraded?)
  end
end
