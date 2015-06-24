# Copyright (c) 2013-2015 Cisco and/or its affiliates.
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

require File.expand_path("../ciscotest", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/aaa_authentication_login", __FILE__)

class TestAaaAuthenticationLogin < CiscoTestCase
  DEFAULT_AAA_AUTHENTICATION_LOGIN_ASCII_AUTH = false
  DEFAULT_AAA_AUTHENTICATION_LOGIN_CHAP_ENABLE= false
  DEFAULT_AAA_AUTHENTICATION_LOGIN_ERROR_ENABLE = false
  DEFAULT_AAA_AUTHENTICATION_LOGIN_MSCHAP_ENABLE= false
  DEFAULT_AAA_AUTHENTICATION_LOGIN_MSCHAPV2_ENABLE = false

  def aaaauthenticationlogin_detach(authlogin)
    # Reset the device to a clean test state. Note that AAA will raise an error
    # when disabling an authentication method while a different type is present.
    s = @device.cmd("show run | i 'aaa authentication login'")
    if s[/aaa authentication login (\S+) enable/]
      @device.cmd("conf t ; no aaa authentication login #{Regexp.last_match(1)} enable ; end")
      node.cache_flush
    end
    authlogin.ascii_authentication = DEFAULT_AAA_AUTHENTICATION_LOGIN_ASCII_AUTH
    authlogin.error_display = DEFAULT_AAA_AUTHENTICATION_LOGIN_ERROR_ENABLE
  end

  def get_match_line(name)
    s = @device.cmd("show run aaa all | no-more")
    prefix = "aaa authentication login"
    line = /#{prefix} #{name}/.match(s)
    line
  end

  def test_aaaauthenticationlogin_get_ascii_authentication
    aaaauthlogin = AaaAuthenticationLogin

    s = @device.cmd("configure terminal")
    s = @device.cmd("no aaa authentication login ascii-authentication")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    refute(aaaauthlogin.ascii_authentication,
                 "Error: AAA authentication login ascii get\n" +
                 "See CSCuu12667 (4/29/15)")

    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login ascii-authentication")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert(aaaauthlogin.ascii_authentication,
                 "Error: AAA authentication login ascii get with preconfig")
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_get_default_ascii_authentication
    aaaauthlogin = AaaAuthenticationLogin
    s = @device.cmd("configure terminal")
    s = @device.cmd("no aaa authentication login ascii-authentication")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(DEFAULT_AAA_AUTHENTICATION_LOGIN_ASCII_AUTH,
                 aaaauthlogin.default_ascii_authentication,
                 "Error: AAA authentication login, default ascii incorrect")
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_set_ascii_authentication
    state = true

    aaaauthlogin = AaaAuthenticationLogin

    aaaauthlogin.ascii_authentication = state
    line = get_match_line("ascii-authentication")
    refute_nil(line, "Error: AAA authentication login ascii not configured #{state}")
    assert(aaaauthlogin.ascii_authentication,
                 "Error: AAA authentication login asci not set #{state}\n" +
                 "See CSCuu12667 (4/29/15)")

    # Now bring it back to default
    state = DEFAULT_AAA_AUTHENTICATION_LOGIN_ASCII_AUTH
    aaaauthlogin.ascii_authentication = state
    line = get_match_line("ascii-authentication")
    refute_nil(line, "Error:  AAA authentication login, default ascii not configured")
    refute(aaaauthlogin.ascii_authentication,
                 "Error: AAA authentication login asci not set #{state}\n" +
                 "See CSCuu12667 (4/29/15)")

    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_get_chap
    aaaauthlogin = AaaAuthenticationLogin

    s = @device.cmd("configure terminal")
    s = @device.cmd("no aaa authentication login chap enable")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    refute(aaaauthlogin.chap,
                 "Error: AAA authentication login chap get\n" +
                 "See CSCuu12667 (4/29/15)")

    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login chap enable")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert(aaaauthlogin.chap,
                 "Error: AAA authentication login chap get with preconfig\n" +
                 "See CSCuu12667 (4/29/15)")
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_get_default_chap
    aaaauthlogin = AaaAuthenticationLogin

    s = @device.cmd("configure terminal")
    s = @device.cmd("no aaa authentication login chap enable")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(DEFAULT_AAA_AUTHENTICATION_LOGIN_CHAP_ENABLE,
                 aaaauthlogin.default_chap,
                 "Error: AAA authentication login, default chap incorrect")
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_set_chap
    state = true

    aaaauthlogin = AaaAuthenticationLogin

    aaaauthlogin.chap = state
    line = get_match_line("chap enable")
    refute_nil(line, "Error: AAA authentication login chap not configured #{state}")
    assert(aaaauthlogin.chap,
                 "Error: AAA authentication login chap not set #{state}\n" +
                 "See CSCuu12667 (4/29/15)")

    # Now bring it back to default
    state = DEFAULT_AAA_AUTHENTICATION_LOGIN_CHAP_ENABLE
    aaaauthlogin.chap = state
    line = get_match_line("chap enable")
    refute_nil(line, "Error:  AAA authentication login, default chap not configured")
    refute(aaaauthlogin.chap,
                 "Error: AAA authentication login chap not set #{state}\n" +
                 "See CSCuu12667 (4/29/15)")

    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_get_error_display
    aaaauthlogin = AaaAuthenticationLogin

    s = @device.cmd("configure terminal")
    s = @device.cmd("no aaa authentication login error-enable")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    refute(aaaauthlogin.error_display,
                 "Error: AAA authentication login error display get")

    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login error-enable")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert(aaaauthlogin.error_display,
                 "Error: AAA authentication login error display get with preconfig")
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_get_default_error_display
    aaaauthlogin = AaaAuthenticationLogin

    s = @device.cmd("configure terminal")
    s = @device.cmd("no aaa authentication login error-enable")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(DEFAULT_AAA_AUTHENTICATION_LOGIN_ERROR_ENABLE,
                 aaaauthlogin.default_error_display,
                 "Error: AAA authentication login, default error display incorrect")
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_set_error_display
    state = true

    aaaauthlogin = AaaAuthenticationLogin

    aaaauthlogin.error_display = state
    line = get_match_line("error-enable")
    refute_nil(line, "Error: AAA authentication login error display not configured #{state}")
    assert(aaaauthlogin.error_display,
                 "Error: AAA authentication login error display not set #{state}")

    # Now bring it back to default
    state = DEFAULT_AAA_AUTHENTICATION_LOGIN_ERROR_ENABLE
    aaaauthlogin.error_display = state
    line = get_match_line("error-enable")
    refute_nil(line, "Error:  AAA authentication login, default error display not configured")
    refute(aaaauthlogin.error_display,
                 "Error: AAA authentication login error display not set #{state}")

    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_get_mschap
    aaaauthlogin = AaaAuthenticationLogin

    s = @device.cmd("configure terminal")
    s = @device.cmd("no aaa authentication login mschap enable")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    refute(aaaauthlogin.mschap,
                 "Error: AAA authentication login mschap get\n" +
                 "See CSCuu12667 (4/29/15)")

    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login mschap enable")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert(aaaauthlogin.mschap,
                 "Error: AAA authentication login mschap get with preconfig\n" +
                 "See CSCuu12667 (4/29/15)")
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_get_default_mschap
    aaaauthlogin = AaaAuthenticationLogin

    s = @device.cmd("configure terminal")
    s = @device.cmd("no aaa authentication login mschap enable")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(DEFAULT_AAA_AUTHENTICATION_LOGIN_MSCHAP_ENABLE,
                 aaaauthlogin.default_mschap,
                 "Error: AAA authentication login, default mschap incorrect")
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_set_mschap
    state = true

    aaaauthlogin = AaaAuthenticationLogin

    aaaauthlogin.mschap = state
    line = get_match_line("mschap enable")
    refute_nil(line, "Error: AAA authentication login mschap not configured #{state}")
    assert(aaaauthlogin.mschap,
                 "Error: AAA authentication login mschap not set #{state}\n" +
                 "See CSCuu12667 (4/29/15)")

    # Now bring it back to default
    state = DEFAULT_AAA_AUTHENTICATION_LOGIN_MSCHAP_ENABLE
    aaaauthlogin.mschap = state
    line = get_match_line("mschap enable")
    refute_nil(line, "Error:  AAA authentication login, default mschap not configured")
    refute(aaaauthlogin.mschap,
                 "Error: AAA authentication login mschap not set #{state}\n" +
                 "See CSCuu12667 (4/29/15)")

    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_get_mschapv2
    aaaauthlogin = AaaAuthenticationLogin

    s = @device.cmd("configure terminal")
    s = @device.cmd("no aaa authentication login mschapv2 enable")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    refute(aaaauthlogin.mschapv2,
                 "Error: AAA authentication login mschapv2 get\n" +
                 "See CSCuu12667 (4/29/15)")

    s = @device.cmd("configure terminal")
    s = @device.cmd("aaa authentication login mschapv2 enable")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert(aaaauthlogin.mschapv2,
                 "Error: AAA authentication login mschapv2 get with preconfig\n" +
                 "See CSCuu12667 (4/29/15)")
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_get_default_mschapv2
    aaaauthlogin = AaaAuthenticationLogin

    s = @device.cmd("configure terminal")
    s = @device.cmd("no aaa authentication login mschapv2 enable")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush
    assert_equal(DEFAULT_AAA_AUTHENTICATION_LOGIN_MSCHAPV2_ENABLE,
                 aaaauthlogin.default_mschapv2,
                 "Error: AAA authentication login, default mschapv2 incorrect")
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_aaaauthenticationlogin_set_mschapv2
    state = true

    aaaauthlogin = AaaAuthenticationLogin

    aaaauthlogin.mschapv2 = state
    line = get_match_line("mschapv2 enable")
    refute_nil(line, "Error: AAA authentication login mschapv2 not configured #{state}")
    assert(aaaauthlogin.mschapv2,
                 "Error: AAA authentication login mschapv2 not set #{state}\n" +
                 "See CSCuu12667 (4/29/15)")

    # Now bring it back to default
    state = DEFAULT_AAA_AUTHENTICATION_LOGIN_MSCHAPV2_ENABLE
    aaaauthlogin.mschapv2 = state
    line = get_match_line("mschapv2 enable")
    refute_nil(line, "Error:  AAA authentication login, default mschapv2 not configured")
    refute(aaaauthlogin.mschapv2,
                 "Error: AAA authentication login mschapv2 not set #{state}\n" +
                 "See CSCuu12667 (4/29/15)")

    aaaauthenticationlogin_detach(aaaauthlogin)
  end
end
