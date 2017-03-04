# October 2016, Michael G Wiebe
#
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

require_relative 'node_util'

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

    # Deletes currently booted image
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
    def self.image_version(image=nil, media=nil)
      # Returns version of currently booted image by default
      if image && media
        config_get('service', 'image_version', image: image, media: media)
      else
        config_get('show_version', 'version').split(' ')[0]
      end
    end

    # Return true if box is online and config mode is ready to be used
    def self.box_online?
      output = config_set('service', 'is_box_online')
      output[0]['body'] == {}
    end

    def self.save_config
      config_set('service', 'save_config')
    rescue Cisco::CliError => e
      raise e
    end

    # Returns True if device upgraded
    def self.upgraded?
      return false unless config_get('service', 'upgraded')
      (0..500).each do
        sleep 1
        return true if box_online?
      end
      fail 'Configuration is still blocked'
    end

    # Attempts to upgrade the device to 'image'
    def self.upgrade(version, image, media='bootflash:', del_boot=false,
                     force_all=false)
      # IMPORTANT - Check if version of image equals the version provided.
      # This is to avoid entering a loop with the Programmability Agent
      # continuously trying to reload the device if versions don't match.
      if media == 'bootflash:'
        image_ver = image_version(image, media)
        err_str = "Version Mismatch.\n
                   The version of the image:#{image_ver}\n
                   The version provided:#{version}\n
                   Aborting upgrade."
        fail err_str unless image_ver == version
      end
      delete_boot(media) if del_boot
      force_all ? upgrade_str = 'upgrade_force' : upgrade_str = 'upgrade'
      begin
        config_set('service', upgrade_str, image: image, media: media)
      rescue Cisco::RequestFailed
        # Catch 'Backend Processing Error'. Install continues inspite of the
        # error thrown. Resend install command and expect a CliError.
        begin
          config_set('service', upgrade_str, image: image, media: media)
        rescue Cisco::CliError => e
          raise e unless
            e.message.include?('Another install procedure may be in progress')
        end
      end
    end
  end
end
