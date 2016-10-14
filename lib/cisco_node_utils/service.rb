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
    def self.clear_status
      puts "Calling: #{__method__}"
      config_set('service', 'clear_status')
    end

    def self.delete(image, media='bootflash:')
      puts "Calling: #{__method__}"
      config_set('service', 'delete', image: image, media: media)
    rescue Cisco::CliError => e
      # cmd will syntax reject when image does not exist.
      raise unless e.clierror =~ /No such file or directory/
    end

    def self.delete_boot(image, media='bootflash:')
      puts "Calling: #{__method__}"
      config_set('service', 'delete_boot', image: image, media: media)
    rescue Cisco::CliError => e
      # cmd will syntax reject when image does not exist.
      raise unless e.clierror =~ /No such file or directory/
    end

    def self.save_config
      puts "Calling: #{__method__}"
      config_set('service', 'save_config')
    end

    def self.upgraded?
      puts "Calling: #{__method__}"
      config_get('service', 'upgraded')
    end

    def self.upgrade(image, media='bootflash:')
      puts "Calling: #{__method__}"
      config_set('service', 'upgrade', image: image, media: media)
    end
  end
end
