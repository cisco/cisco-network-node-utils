# TacacsServerHost class
#
# Alex Hunsberger, March 2015
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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
require File.join(File.dirname(__FILE__), 'tacacs_server')

module Cisco
class TacacsServerHost
  attr_reader :name
  @@node = Cisco::Node.instance
  @@hosts = {}

  def initialize(name, create=true)
    raise TypeError unless name.is_a? String
    raise ArgumentError if name.empty?
    @name = name

    if create
      # feature Tacacs+ must be enabled to create a host
      TacacsServer.new.enable unless TacacsServer.enabled
      @@node.config_set("tacacs_server_host", "host", "", name)
    end
  end

  def TacacsServerHost.hosts
    @@hosts = {}

    return @@hosts unless TacacsServer.enabled

    hosts = @@node.config_get("tacacs_server_host", "hosts")
    unless hosts.nil?
      hosts = [hosts] if hosts.is_a?(Hash)
      hosts.each { |name|
        @@hosts[name] = TacacsServerHost.new(name, false) if @@hosts[name].nil?
      }
    end
    @@hosts
  end

  def destroy
    @@node.config_set("tacacs_server_host", "host", "no", @name)
    @@hosts.delete(@name) unless @@hosts.nil?
  end

  def port
    p = @@node.config_get("tacacs_server_host", "port", @name)
    raise "unable to retrieve port information for #{@name}" if p.nil?
    p.first.to_i
  end

  def port=(n)
    @@node.config_set("tacacs_server_host", "port", @name, n.to_i)
  end

  def TacacsServerHost.default_port
    @@node.config_get_default("tacacs_server_host", "port")
  end

  def encryption_type
    type = @@node.config_get("tacacs_server_host", "encryption_type", @name)
    type.nil? ? TACACS_SERVER_ENC_UNKNOWN : type.first.to_i
  end

  def TacacsServerHost.default_encryption_type
    TacacsServer.default_encryption_type
  end

  def encryption_password
    pass = @@node.config_get("tacacs_server_host", "encryption_password", @name)
    pass.nil? ? TacacsServerHost.default_encryption_password : pass.first
  end

  def TacacsServerHost.default_encryption_password
    @@node.config_get_default("tacacs_server_host", "encryption_password")
  end

  def encryption_key_set(enctype, password)
    raise TypeError unless enctype.is_a? Fixnum
    raise ArgumentError if password and not [TACACS_SERVER_ENC_NONE,
                                             TACACS_SERVER_ENC_CISCO_TYPE_7,
                                             TACACS_SERVER_ENC_UNKNOWN].include? enctype
    # if enctype is TACACS_SERVER_ENC_UNKNOWN, we'll unset the key
    if enctype == TACACS_SERVER_ENC_UNKNOWN
      # if current encryption type is not TACACS_SERVER_ENC_UNKNOWN, we need
      # to unset the key value. Otherwise, the box is not configured with key,
      # thus we don't need to do anything
      if encryption_type != TACACS_SERVER_ENC_UNKNOWN
         @@node.config_set("tacacs_server_host", "encryption", "no", @name,
                        encryption_type,
                        encryption_password)
      end
    else
      @@node.config_set("tacacs_server_host", "encryption", "", @name, enctype, password)
    end
  end

  def timeout
    t = @@node.config_get("tacacs_server_host", "timeout", @name)
    t.nil? ? TacacsServerHost.default_timeout : t.first.to_i
  end

  def timeout=(t)
    raise TypeError unless t.is_a? Fixnum
    return if t == timeout

    @@node.config_set("tacacs_server_host", "timeout", "", @name, t)
  end

  def TacacsServerHost.default_timeout
    @@node.config_get_default("tacacs_server_host", "timeout")
  end
end
end
