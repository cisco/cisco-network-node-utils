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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/vtp'

# TestVtp - Minitest for Vtp node utility class
class TestVtp < CiscoTestCase
  def setup
    super
    no_feature_vtp
  end

  def teardown
    no_feature_vtp
    super
  end

  def no_feature_vtp
    # VTP will raise an error if the domain is configured twice so we need to
    # turn the feature off for a clean test.
    config('no feature vtp')
  end

  def vtp_domain(domain)
    vtp = Vtp.new
    vtp.domain = domain
    vtp
  end

  def test_vtp_disabled
    vtp = Vtp.new(false)
    assert_empty(vtp.domain)
    assert_equal(vtp.default_password, vtp.password)
    assert_equal(vtp.default_filename, vtp.filename)
    assert_equal(vtp.default_version, vtp.version)
    refute(Vtp.enabled, 'VTP feature was unexpectedly enabled?')
  end

  def test_vtp_enabled_but_no_domain
    vtp = Vtp.new(false)
    config('feature vtp')
    assert(Vtp.enabled)
    assert_empty(vtp.domain)
    assert_equal(vtp.default_password, vtp.password)
    assert_equal(vtp.default_filename, vtp.filename)
    assert_equal(vtp.default_version, vtp.version)
    # Can set these without setting domain
    vtp.filename = 'bootflash:/foo.bar'
    assert_equal('bootflash:/foo.bar', vtp.filename)
    vtp.version = 1
    assert_equal(1, vtp.version)
    # Can't set any of the below without setting a domain first
    assert_raises(RuntimeError) do
      vtp.password = 'hello'
    end
  end

  def test_vtp_domain_enable_disable
    assert_empty(Vtp.domain)
    vtp = vtp_domain('enable')
    assert_equal('enable', Vtp.domain)
    vtp.destroy
    assert_empty(Vtp.domain)
  end

  def test_vtp_create_valid
    vtp_domain('accounting')
    s = @device.cmd("show run vtp | incl '^vtp domain'")
    assert_match(/^vtp domain accounting/, s,
                 'Error: failed to create vtp domain')
  end

  def test_vtp_domain_name_change
    vtp = vtp_domain('accounting')
    vtp_domain('uplink')
    assert_equal('uplink', vtp.domain,
                 'Error: vtp domain name incorrect')
  end

  def test_vtp_create_preconfig_no_change
    config('feature vtp', 'vtp domain accounting')

    vtp = vtp_domain('accounting')
    assert_equal('accounting', vtp.domain,
                 'Error: vtp domain wrong')
  end

  def test_vtp_create_double
    vtp = vtp_domain('accounting')
    vtp_new = vtp_domain('accounting')

    assert_equal('accounting', vtp.domain,
                 'Error: vtp domain wrong')
    assert_equal('accounting', vtp_new.domain,
                 'Error: vtp_new domain wrong')
  end

  def test_vtp_create_domain_invalid
    assert_raises(ArgumentError) do
      vtp_domain(node)
    end
  end

  def test_vtp_create_domain_nil
    assert_raises(ArgumentError) do
      vtp_domain(nil)
    end
  end

  def test_vtp_create_domain_empty
    assert_raises(ArgumentError) do
      vtp_domain('')
    end
  end

  def test_vtp_assignment
    vtp = vtp_domain('accounting')
    vtp.password = 'copy_test'
    assert_equal('copy_test', vtp.password,
                 'Error: vtp password not set')
    vtp_extra = vtp
    assert_equal('copy_test', vtp_extra.password,
                 'Error: vtp password not set')
  end

  def test_vtp_domain_get
    vtp = vtp_domain('accounting')
    assert_equal('accounting', vtp.domain,
                 'Error: vtp domain incorrect')
  end

  def test_vtp_password_nil
    vtp = vtp_domain('accounting')
    assert_raises(TypeError) do
      vtp.password = nil
    end
  end

  def test_vtp_password_default
    vtp = vtp_domain('accounting')
    vtp.password = 'test_me'
    assert_equal('test_me', vtp.password,
                 'Error: vtp password not correct')

    vtp.password = vtp.default_password
    assert_equal(node.config_get_default('vtp', 'password'), vtp.password,
                 'Error: vtp password not correct')
  end

  def test_vtp_password_zero_length
    vtp = vtp_domain('accounting')
    vtp.password = ''
    assert_equal('', vtp.password,
                 'Error: vtp password not empty')
  end

  def test_vtp_password_get
    vtp = vtp_domain('accounting')

    config('vtp password cisco123')
    assert_equal('cisco123', vtp.password,
                 'Error: vtp password not correct')
  end

  def test_vtp_password_get_not_set
    vtp = vtp_domain('accounting')
    assert_equal('', vtp.password,
                 'Error: vtp password not empty')
  end

  def test_vtp_password_clear
    vtp = vtp_domain('accounting')
    vtp.password = 'cisco123'
    assert_equal('cisco123', vtp.password,
                 'Error: vtp password not set')

    vtp.password = ''
    assert_equal('', vtp.password,
                 'Error: vtp default password not set')
  end

  def test_vtp_password_valid
    vtp = vtp_domain('accounting')
    alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789'
    password = ''
    1.upto(Vtp::MAX_VTP_PASSWORD_SIZE - 1) do |i|
      password += alphabet[i % alphabet.size, 1]
      vtp.password = password
      assert_equal(password.rstrip, vtp.password,
                   'Error: vtp password not set')
    end
  end

  def test_vtp_password_too_long
    vtp = vtp_domain('accounting')
    password = 'a' * (Vtp::MAX_VTP_PASSWORD_SIZE + 1)
    assert_raises(ArgumentError) { vtp.password = password }
  end

  def test_vtp_password_special_characters
    vtp = vtp_domain('password')
    vtp.password = 'hello!//\\#%$x'
    assert_equal('hello!//\\#%$x', vtp.password)
  end

  def test_vtp_filename_nil
    vtp = vtp_domain('accounting')
    assert_raises(TypeError) do
      vtp.filename = nil
    end
  end

  def test_vtp_filename_valid
    vtp = vtp_domain('accounting')
    vtp.filename = 'bootflash:/test.dat'
    assert_equal('bootflash:/test.dat', vtp.filename,
                 'Error: vtp file content wrong')
  end

  def test_vtp_filename_zero_length
    vtp = vtp_domain('accounting')
    vtp.filename = vtp.default_filename
    assert_equal(node.config_get_default('vtp', 'filename'), vtp.filename,
                 'Error: vtp file content wrong')

    # send in 'no' to remove the config. That will cause the default
    # to get reapplied.
    vtp.filename = ''
    assert_equal(node.config_get_default('vtp', 'filename'), vtp.filename,
                 'Error: vtp file content wrong')
  end

  def test_vtp_filename_auto_enable
    vtp = Vtp.new(false)
    refute(Vtp.enabled, 'VTP should not be enabled')
    vtp.filename = 'bootflash:/foo.bar'
    assert(Vtp.enabled)
    assert_equal('bootflash:/foo.bar', vtp.filename)
  end

  def test_vtp_version_valid
    vtp = vtp_domain('accounting')
    vtp.version = vtp.default_version
    assert_equal(node.config_get_default('vtp', 'version'), vtp.version,
                 'Error: vtp version not default')
  end

  def test_vtp_version3_valid
    vtp = vtp_domain('accounting')

    ref = cmd_ref.lookup('vtp', 'version')
    assert(ref, 'Error, reference not found for vtp version3')

    assert_result(ref.test_config_result(3), 'Error: vtp version3 error') do
      vtp.version = 3
      vtp.version
    end
  end

  # Decides whether to check for a raised Exception or an equal value.
  def assert_result(expected_result, err_msg, &block)
    if /Error/ =~ expected_result.to_s
      if expected_result.is_a?(String)
        expected_result = Object.const_get(expected_result)
      end
      assert_raises(expected_result, &block)
    else
      value = block.call
      assert_equal(expected_result, value, err_msg)
    end
  end

  def test_vtp_version_invalid
    vtp = vtp_domain('accounting')
    assert_raises(Cisco::CliError) do
      vtp.version = 34
    end
  end

  def test_vtp_version_default
    vtp = vtp_domain('accounting')
    vtp.version = 2
    assert_equal(2, vtp.version,
                 'Error: vtp version not correct')
    vtp.version = vtp.default_version
    assert_equal(node.config_get_default('vtp', 'version'), vtp.version,
                 'Error: vtp version not default')
  end

  def test_vtp_version_auto_enable
    vtp = Vtp.new(false)
    refute(Vtp.enabled, 'VTP should not be enabled')
    vtp.version = 1
    assert(Vtp.enabled)
    assert_equal(1, vtp.version)
  end

  def test_vtp_feature_enable_disable
    Vtp.new.enable
    assert(Vtp.enabled, 'Error: vtp is not enabled')

    Vtp.new.destroy
    refute(Vtp.enabled, 'Error: vtp is not disabled')
  end
end
