# VTP provider class
#
# Mike Wiebe, November 2014
#
# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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

require File.join(File.dirname(__FILE__), 'node')

module Cisco
class Vtp
  attr_reader :name

  MAX_VTP_DOMAIN_NAME_SIZE = 32
  MAX_VTP_PASSWORD_SIZE    = 64

  @@node = Node.instance

  # Constructor for Vtp
  def initialize(instantiate=true)
    enable if instantiate and not Vtp.enabled
  end

  def Vtp.enabled
    not @@node.config_get("vtp", "feature").nil?
  end

  def enable
    @@node.config_set("vtp", "feature", "")
  end

  # Disable vtp feature
  def destroy
    @@node.config_set("vtp", "feature", "no")
  end

  # Get vtp domain name
  def Vtp.domain
    @@node.config_get("vtp", "domain")
  end

  def domain
    Vtp.domain
  end

  # Set vtp domain name
  def domain=(domain)
    raise ArgumentError unless domain and domain.is_a? String and
                               domain.length.between?(1, MAX_VTP_DOMAIN_NAME_SIZE)
    begin
      @@node.config_set("vtp", "domain", domain)
    rescue Cisco::CliError => e
      # cmd will syntax reject when setting name to same name
      raise unless e.clierror =~ /ERROR: Domain name already set to /
    end
  end

  # Get vtp password
  def password
    # Unfortunately nxapi returns "\\" when the password is not set
    password = @@node.config_get("vtp", "password")
    return '' if password.nil?
    password.gsub(/\\/, '')
  end

  # Set vtp password
  def password=(password)
    raise TypeError if password.nil?
    raise TypeError unless password.is_a? String
    raise ArgumentError if password.length > MAX_VTP_PASSWORD_SIZE
    password == default_password ?
      @@node.config_set("vtp", "password", "no", "") :
      @@node.config_set("vtp", "password", "", password)
  end

  # Get default vtp password
  def default_password
    @@node.config_get_default("vtp", "password")
  end

  # Get vtp filename
  def filename
    match = @@node.config_get("vtp", "filename")
    match.nil? ? default_filename : match.first
  end

  # Set vtp filename
  def filename=(uri)
    raise TypeError if uri.nil?
    uri.empty? ?
      @@node.config_set("vtp", "filename", "no", "") :
      @@node.config_set("vtp", "filename", "", uri)
  end

  # Get default vtp filename
  def default_filename
    @@node.config_get_default("vtp", "filename")
  end

  # Get vtp version
  def version
    match = @@node.config_get("vtp", "version")
    match.nil? ? default_version : match.first.to_i
  end

  # Set vtp version
  def version=(version)
    @@node.config_set("vtp", "version", "#{version}")
  end

  # Get default vtp version
  def default_version
    @@node.config_get_default("vtp", "version")
  end
end
end
