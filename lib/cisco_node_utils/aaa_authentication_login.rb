#
# NXAPI implementation of AaaAuthenticationLogin class
#
# April 2015, Alex Hunsberger
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
#

require File.join(File.dirname(__FILE__), 'node')

module Cisco
class AaaAuthenticationLogin
  @@node = Cisco::Node.instance

  # There is no "feature aaa" or "aaa new-model" on nxos, and only one
  # instance which is always available

  # TODO: onep didn't implement mschap, mschapv2, chap, default fallback, console
  # fallback. Should I?

  def AaaAuthenticationLogin.ascii_authentication
    not @@node.config_get("aaa_authentication_login", "ascii_authentication").nil?
  end

  def AaaAuthenticationLogin.ascii_authentication=(val)
    no_cmd = val ? "" : "no"
    @@node.config_set("aaa_authentication_login", "ascii_authentication", no_cmd)
  end

  def AaaAuthenticationLogin.default_ascii_authentication
    @@node.config_get_default("aaa_authentication_login", "ascii_authentication")
  end

  def AaaAuthenticationLogin.chap
    not @@node.config_get("aaa_authentication_login", "chap").nil?
  end

  def AaaAuthenticationLogin.chap=(val)
    no_cmd = val ? "" : "no"
    @@node.config_set("aaa_authentication_login", "chap", no_cmd)
  end

  def AaaAuthenticationLogin.default_chap
    @@node.config_get_default("aaa_authentication_login", "chap")
  end

  def AaaAuthenticationLogin.error_display
    not @@node.config_get("aaa_authentication_login", "error_display").nil?
  end

  def AaaAuthenticationLogin.error_display=(val)
    no_cmd = val ? "" : "no"
    @@node.config_set("aaa_authentication_login", "error_display", no_cmd)
  end

  def AaaAuthenticationLogin.default_error_display
    @@node.config_get_default("aaa_authentication_login", "error_display")
  end

  def AaaAuthenticationLogin.mschap
    not @@node.config_get("aaa_authentication_login", "mschap").nil?
  end

  def AaaAuthenticationLogin.mschap=(val)
    no_cmd = val ? "" : "no"
    @@node.config_set("aaa_authentication_login", "mschap", no_cmd)
  end

  def AaaAuthenticationLogin.default_mschap
    @@node.config_get_default("aaa_authentication_login", "mschap")
  end

  def AaaAuthenticationLogin.mschapv2
    not @@node.config_get("aaa_authentication_login", "mschapv2").nil?
  end

  def AaaAuthenticationLogin.mschapv2=(val)
    no_cmd = val ? "" : "no"
    @@node.config_set("aaa_authentication_login", "mschapv2", no_cmd)
  end

  def AaaAuthenticationLogin.default_mschapv2
    @@node.config_get_default("aaa_authentication_login", "mschapv2")
  end
end
end
