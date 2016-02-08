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

module Cisco
  # Vtp - node utility class for VTP configuration management
  class Vtp < NodeUtil
    attr_reader :name

    MAX_VTP_DOMAIN_NAME_SIZE = 32
    MAX_VTP_PASSWORD_SIZE    = 64

    # Constructor for Vtp
    def initialize(instantiate=true)
      enable if instantiate && !Vtp.enabled
    end

    def self.enabled
      config_get('vtp', 'feature')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    def enable
      config_set('vtp', 'feature', '')
    end

    # Disable vtp feature
    def destroy
      config_set('vtp', 'feature', 'no')
    end

    # Get vtp domain name
    def self.domain
      enabled ? config_get('vtp', 'domain') : ''
    end

    def domain
      Vtp.domain
    end

    # Set vtp domain name
    def domain=(d)
      fail ArgumentError unless d && d.is_a?(String) &&
                                d.length.between?(1, MAX_VTP_DOMAIN_NAME_SIZE)
      enable unless Vtp.enabled
      begin
        config_set('vtp', 'domain', d)
      rescue Cisco::CliError => e
        # cmd will syntax reject when setting name to same name
        raise unless e.clierror =~ /ERROR: Domain name already set to /
      end
    end

    # Get vtp password
    def password
      # Unfortunately nxapi returns "\\" when the password is not set
      password = config_get('vtp', 'password') if Vtp.enabled
      return '' if password.nil? || password == '\\'
      password
    end

    # Set vtp password
    def password=(password)
      fail TypeError if password.nil?
      fail TypeError unless password.is_a? String
      fail ArgumentError if password.length > MAX_VTP_PASSWORD_SIZE
      enable unless Vtp.enabled
      begin
        if password == default_password
          config_set('vtp', 'password', 'no', '')
        else
          config_set('vtp', 'password', '', password)
        end
      rescue Cisco::CliError => e
        raise unless e.clierror =~ /password cannot be set for NULL domain/
        unless password == default_password
          raise 'Setting VTP password requires first setting VTP domain'
        end
      end
    end

    # Get default vtp password
    def default_password
      config_get_default('vtp', 'password')
    end

    # Get vtp filename
    def filename
      config_get('vtp', 'filename')
    end

    # Set vtp filename
    def filename=(uri)
      fail TypeError if uri.nil?
      enable unless Vtp.enabled
      if uri.empty?
        config_set('vtp', 'filename', 'no', '')
      else
        config_set('vtp', 'filename', '', uri)
      end
    end

    # Get default vtp filename
    def default_filename
      config_get_default('vtp', 'filename')
    end

    # Get vtp version
    def version
      Vtp.enabled ? config_get('vtp', 'version') : default_version
    end

    # Set vtp version
    def version=(version)
      enable unless Vtp.enabled
      config_set('vtp', 'version', "#{version}")
    end

    # Get default vtp version
    def default_version
      config_get_default('vtp', 'version')
    end
  end
end
