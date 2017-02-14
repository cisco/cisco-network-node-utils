# October 2016, Michael G Wiebe
#
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

require_relative 'node_util'
require 'pry'

module Cisco
  # Service - node util class for managing device services
  class Service < NodeUtil
    # Delete install logs from previous installation
    def self.clear_status
      config_set('service', 'clear_status')
    end

    # Deletes 'image' from 'media'
    def self.delete(image, media='bootflash:')
      config_set('service', 'delete', image: image, media: media)
    rescue Cisco::CliError => e
      raise e
    end

    # Deletes the image that the device is currently booted up with
    def self.delete_boot(media='bootflash:')
      # Incase of a N9K, N3K and N9Kv the system and kickstart images are
      # the same.
      # Incase of a N5K, N6K and N7K the system and kickstart images are
      # different.
      system_image = config_get('show_version', 'system_image').split('/')[-1]
      kickstart_image = config_get('show_version', 'boot_image').split('/')[-1]
      if kickstart_image == system_image
        config_set('service', 'delete_boot', image: system_image, media: media)
      else
        config_set('service', 'delete_boot', image: system_image,
                                             media: media)
        config_set('service', 'delete_boot', image: kickstart_image,
                                             media: media)
      end
    rescue Cisco::CliError => e
      raise e
    end

    # Returns version of the 'image'
    def self.image_version(image='', media='bootflash:')
      # If no image is passed in check the version of the image which is
      # booted up on the switch.
      if image == ''
        config_get('show_version', 'version').split(' ')[0]
      else
        config_get('service', 'image_version', image: image, media: media)
      end
    end

    def self.save_config
      config_set('service', 'save_config')
    end

    # Returns True if device upgraded
    def self.upgraded?
      config_get('service', 'upgraded')
    end

    # Attempts to upgrade the device to 'image'
    def self.upgrade(image, media='bootflash:')
      config_set('service', 'upgrade', image: image, media: media)
    end
  end
end
