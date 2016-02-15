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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/aaa_authentication_login'

# Test class for AAA Authentication Login
class TestAaaAuthenticationLogin < CiscoTestCase
  # DEFAULT(:ascii_authentication)
  # => false
  # rubocop:disable Style/MethodName
  def DEFAULT(prop_name)
    cmd_ref.lookup('aaa_authentication_login', prop_name.to_s).default_value
  end
  # rubocop:enable Style/MethodName

  def aaaauthenticationlogin_detach(authlogin)
    # Reset the device to a clean test state. Note that AAA will raise an error
    # when disabling an authentication method while a different type is present.
    s = @device.cmd("show run | i 'aaa authentication login'")
    if s[/aaa authentication login (\S+) enable/]
      config("no aaa authentication login #{Regexp.last_match(1)} enable")
    end
    authlogin.ascii_authentication = DEFAULT(:ascii_authentication)
    authlogin.error_display = DEFAULT(:error_display)
  end

  def test_get_ascii_authentication
    aaaauthlogin = AaaAuthenticationLogin

    config('no aaa authentication login ascii-authentication')
    refute(aaaauthlogin.ascii_authentication)

    config('aaa authentication login ascii-authentication')
    assert(aaaauthlogin.ascii_authentication,
           'Error: AAA authentication login ascii get with preconfig')
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_get_default_ascii_authentication
    aaaauthlogin = AaaAuthenticationLogin
    config('no aaa authentication login ascii-authentication')
    assert_equal(DEFAULT(:ascii_authentication),
                 aaaauthlogin.default_ascii_authentication,
                 'Error: AAA authentication login, default ascii incorrect')
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_set_ascii_authentication
    aaaauthlogin = AaaAuthenticationLogin

    aaaauthlogin.ascii_authentication = true
    assert_show_match(command: 'show run aaa all | no-more',
                      pattern: /^aaa authentication login ascii-authentication/)

    aaaauthlogin.ascii_authentication = false
    refute_show_match(command: 'show run aaa all | no-more',
                      pattern: /^aaa authentication login ascii-authentication/)

    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_get_chap
    aaaauthlogin = AaaAuthenticationLogin

    config('no aaa authentication login chap enable')
    refute(aaaauthlogin.chap)

    config('aaa authentication login chap enable')
    assert(aaaauthlogin.chap,
           "Error: AAA authentication login chap get with preconfig\n")
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_get_default_chap
    aaaauthlogin = AaaAuthenticationLogin

    config('no aaa authentication login chap enable')
    assert_equal(DEFAULT(:chap),
                 aaaauthlogin.default_chap,
                 'Error: AAA authentication login, default chap incorrect')
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_set_chap
    aaaauthlogin = AaaAuthenticationLogin

    aaaauthlogin.chap = true
    assert_show_match(command: 'show run aaa all | no-more',
                      pattern: /^aaa authentication login chap enable/)
    aaaauthlogin.chap = false
    refute_show_match(command: 'show run aaa all | no-more',
                      pattern: /^aaa authentication login chap enable/)

    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_get_error_display
    aaaauthlogin = AaaAuthenticationLogin

    config('no aaa authentication login error-enable')
    refute(aaaauthlogin.error_display,
           'Error: AAA authentication login error display get')

    config('aaa authentication login error-enable')
    assert(aaaauthlogin.error_display,
           'Error: AAA authentication login error display get with preconfig')
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_get_default_error_display
    aaaauthlogin = AaaAuthenticationLogin

    config('no aaa authentication login error-enable')
    assert_equal(DEFAULT(:error_display),
                 aaaauthlogin.default_error_display,
                 'Error: default error display incorrect')
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_set_error_display
    aaaauthlogin = AaaAuthenticationLogin

    aaaauthlogin.error_display = true
    assert_show_match(command: 'show run aaa all | no-more',
                      pattern: /^aaa authentication login error-enable/)

    aaaauthlogin.error_display = false
    refute_show_match(command: 'show run aaa all | no-more',
                      pattern: /^aaa authentication login error-enable/)

    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_get_mschap
    aaaauthlogin = AaaAuthenticationLogin

    config('no aaa authentication login mschap enable')
    refute(aaaauthlogin.mschap,
           "Error: AAA authentication login mschap get\n")

    config('aaa authentication login mschap enable')
    assert(aaaauthlogin.mschap,
           "Error: AAA authentication login mschap get with preconfig\n")
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_get_default_mschap
    aaaauthlogin = AaaAuthenticationLogin

    config('no aaa authentication login mschap enable')
    assert_equal(DEFAULT(:mschap),
                 aaaauthlogin.default_mschap,
                 'Error: AAA authentication login, default mschap incorrect')
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_set_mschap
    aaaauthlogin = AaaAuthenticationLogin

    aaaauthlogin.mschap = true
    assert_show_match(command: 'show run aaa all | no-more',
                      pattern: /^aaa authentication login mschap enable/)

    aaaauthlogin.mschap = false
    refute_show_match(command: 'show run aaa all | no-more',
                      pattern: /^aaa authentication login mschap enable/)

    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_get_mschapv2
    aaaauthlogin = AaaAuthenticationLogin

    config('no aaa authentication login mschapv2 enable')
    refute(aaaauthlogin.mschapv2,
           "Error: AAA authentication login mschapv2 get\n")

    config('aaa authentication login mschapv2 enable')
    assert(aaaauthlogin.mschapv2,
           "Error: AAA authentication login mschapv2 get with preconfig\n")
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_get_default_mschapv2
    aaaauthlogin = AaaAuthenticationLogin

    config('no aaa authentication login mschapv2 enable')
    assert_equal(DEFAULT(:mschapv2),
                 aaaauthlogin.default_mschapv2,
                 'Error: AAA authentication login, default mschapv2 incorrect')
    aaaauthenticationlogin_detach(aaaauthlogin)
  end

  def test_set_mschapv2
    aaaauthlogin = AaaAuthenticationLogin

    aaaauthlogin.mschapv2 = true
    assert_show_match(command: 'show run aaa all | no-more',
                      pattern: /^aaa authentication login mschapv2 enable/)

    aaaauthlogin.mschapv2 = false
    refute_show_match(command: 'show run aaa all | no-more',
                      pattern: /^aaa authentication login mschapv2 enable/)

    aaaauthenticationlogin_detach(aaaauthlogin)
  end
end
