# Copyright (c) 2013-2016 Cisco and/or its affiliates.
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

require 'yaml'

# Class: PlatformInfo
# This class reads device specific details from platform_info.yaml
# These details can be used to customize unit tests for a device
class PlatformInfo
  # Default constructor for the PlatformInfo class. This class
  # requires the hostname of the device on which UTs are to run
  # to be passed in. The constructor reads platform_info.yaml
  # and stores info for this device in the instance variable
  # @platform_info_hash
  #
  # @param[in] device_name      hostname of device on which
  #                             UTs are to be run
  #
  def initialize(device_name, platform)
    if device_name.nil? || device_name.empty?
      fail 'device name must be specified in PlatformInfo constructor.'
    end
    @platform_info_hash = {}

    begin
      project_info_hash = YAML.load_file(File.join(File.dirname(__FILE__),
                                                   'platform_info.yaml'))
    rescue RuntimeError
      raise 'Error - could not open platform file - platform_info.yaml'
    end

    @platform_info_hash = project_info_hash[device_name]
    @platform_info_hash ||= project_info_hash['default'][platform.to_s]
    fail "Error - could not find #{device_name} device specific information " \
         'in platform_info.yaml' if @platform_info_hash.nil?
  end

  # The following instance method will return the value associated with
  # the specified key from the instance variable @platform_info_hash.
  #
  # @param[in] key  String value indicating the key to be searched for
  #                 in @platform_info_hash
  #
  def get_value_from_key(key)
    fail 'key must be specified in the method get_value_from_key' if key.nil?

    value = @platform_info_hash[key]
    fail "no value exists for the key #{key}" if value.nil?

    value
  end
end
