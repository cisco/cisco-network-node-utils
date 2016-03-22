# Mike Wiebe, November 2014
#
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

require_relative 'node_util'
require_relative 'logger'

module Cisco
  # Vtp - node utility class for VTP configuration management
  class Vtp < NodeUtil
    attr_reader :name

    MAX_VTP_DOMAIN_NAME_SIZE = 32
    MAX_VTP_PASSWORD_SIZE    = 64

    # Constructor for Vtp
    def initialize(instantiate=true)
      Feature.vtp_enable if instantiate
    end

    # Get vtp domain name
    def self.domain
      if Feature.vtp_enabled?
        config_get('vtp', 'domain')
      else
        config_get_default('vtp', 'domain')
      end
    end

    # The only way to remove a vtp domain is to turn the vtp
    # feature off.
    def destroy
      Feature.vtp_disable
    end

    def domain
      Vtp.domain
    end

    # Set vtp domain name
    def domain=(d)
      fail ArgumentError unless d && d.is_a?(String) &&
                                d.length.between?(1, MAX_VTP_DOMAIN_NAME_SIZE)
      config_set('vtp', 'domain', domain: d)
    end

    # Get vtp password
    def password
      # Unfortunately nxapi returns "\\" when the password is not set
      password = config_get('vtp', 'password') if Feature.vtp_enabled?
      return '' if password.nil? || password == '\\'
      password
    end

    # Set vtp password
    def password=(password)
      fail TypeError if password.nil?
      fail TypeError unless password.is_a? String
      fail ArgumentError if password.length > MAX_VTP_PASSWORD_SIZE
      Feature.vtp_enable
      if password == default_password
        config_set('vtp', 'password', state: 'no', password: '')
      else
        config_set('vtp', 'password', state: '', password: password)
      end
    end

    # Get default vtp password
    def default_password
      config_get_default('vtp', 'password')
    end

    # Get vtp filename
    def filename
      filename = config_get('vtp', 'filename') if Feature.vtp_enabled?
      filename.nil? ? default_filename : filename
    end

    # Set vtp filename
    def filename=(uri)
      fail TypeError if uri.nil?
      Feature.vtp_enable
      if uri.empty?
        config_set('vtp', 'filename', state: 'no', uri: '')
      else
        config_set('vtp', 'filename', state: '', uri: uri)
      end
    end

    # Get default vtp filename
    def default_filename
      config_get_default('vtp', 'filename')
    end

    # Get vtp version
    def version
      Feature.vtp_enabled? ? config_get('vtp', 'version') : default_version
    end

    # Set vtp version
    def version=(v)
      Feature.vtp_enable
      config_set('vtp', 'version', version: v)
    end

    # Get default vtp version
    def default_version
      config_get_default('vtp', 'version')
    end
  end
end
