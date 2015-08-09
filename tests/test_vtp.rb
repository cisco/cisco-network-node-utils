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

require File.expand_path("../ciscotest", __FILE__)
require File.expand_path("../../lib/cisco_node_utils/vtp", __FILE__)

class TestVtp < CiscoTestCase
  def setup
    super
    no_feature_vtp
  end

  def no_feature_vtp
    # VTP will raise an error if the domain is configured twice so we need to
    # turn the feature off for a clean test.
    @device.cmd("conf t ; no feature vtp ; end")
    node.cache_flush()
  end

  def vtp_domain(domain)
    vtp = Vtp.new
    vtp.domain = domain
    vtp
  end

  def test_vtp_create_valid
    no_feature_vtp
    vtp = vtp_domain("accounting")
    s = @device.cmd("show run vtp | incl '^vtp domain'")
    assert_match(/^vtp domain accounting/, s,
                 "Error: failed to create vtp domain")
    vtp.destroy
  end

  def test_vtp_domain_name_change
    no_feature_vtp
    vtp = vtp_domain("accounting")
    vtp_new = vtp_domain("uplink")
    assert_equal("uplink", vtp.domain,
                 "Error: vtp domain name incorrect")
    vtp_new.destroy
  end

  def test_vtp_create_preconfig_no_change
    no_feature_vtp
    s = @device.cmd("configure terminal")
    s = @device.cmd("feature vtp")
    s = @device.cmd("vtp domain accounting")
    s = @device.cmd("end")

    # Flush the cache since we've modified the device
    node.cache_flush()

    vtp = vtp_domain("accounting")
    assert_equal("accounting", vtp.domain,
                 "Error: vtp domain wrong")
    vtp.destroy
  end

  def test_vtp_create_double
    no_feature_vtp
    vtp = vtp_domain("accounting")
    vtp_new = vtp_domain("accounting")

    assert_equal("accounting", vtp.domain,
                 "Error: vtp domain wrong")
    assert_equal("accounting", vtp_new.domain,
                 "Error: vtp_new domain wrong")
    vtp_new.destroy
  end

  def test_vtp_create_domain_invalid
    no_feature_vtp
    assert_raises(ArgumentError) do
      vtp_domain(node)
    end
  end

  def test_vtp_create_domain_nil
    no_feature_vtp
    assert_raises(ArgumentError) do
      vtp_domain(nil)
    end
  end

  def test_vtp_create_domain_empty
    no_feature_vtp
    assert_raises(ArgumentError) do
      vtp_domain("")
    end
  end

  def test_vtp_assignment
    no_feature_vtp
    vtp = vtp_domain("accounting")
    vtp.password = "copy_test"
    assert_equal("copy_test", vtp.password,
                 "Error: vtp password not set")
    vtp_extra = vtp
    assert_equal("copy_test", vtp_extra.password,
                 "Error: vtp password not set")
    vtp.destroy
  end

  def test_vtp_domain_get
    no_feature_vtp
    vtp = vtp_domain("accounting")
    assert_equal("accounting", vtp.domain,
                 "Error: vtp domain incorrect")
    vtp.destroy
  end

  def test_vtp_password_nil
    no_feature_vtp
    vtp = vtp_domain("accounting")
    assert_raises(TypeError) do
      vtp.password = nil
    end
    vtp.destroy
  end

  def test_vtp_password_default
    no_feature_vtp
    vtp = vtp_domain("accounting")
    vtp.password = "test_me"
    assert_equal("test_me", vtp.password,
                 "Error: vtp password not correct")

    vtp.password = vtp.default_password
    assert_equal(node.config_get_default("vtp", "password"), vtp.password,
                 "Error: vtp password not correct")

    vtp.destroy
  end

  def test_vtp_password_zero_length
    no_feature_vtp
    vtp = vtp_domain("accounting")
    vtp.password = ""
    assert_equal("", vtp.password,
                 "Error: vtp password not empty")
    vtp.destroy
  end

  def test_vtp_password_get
    no_feature_vtp
    vtp = vtp_domain("accounting")

    s = @device.cmd("configure terminal")
    s = @device.cmd("vtp password cisco123")
    s = @device.cmd("end")
    # Flush the cache since we've modified the device
    node.cache_flush()
    assert_equal("cisco123", vtp.password,
                 "Error: vtp password not correct")
    vtp.destroy
  end

  def test_vtp_password_get_not_set
    no_feature_vtp
    vtp = vtp_domain("accounting")
    assert_equal("", vtp.password,
                 "Error: vtp password not empty")
    vtp.destroy
  end

  def test_vtp_password_clear
    no_feature_vtp
    vtp = vtp_domain("accounting")
    vtp.password = "cisco123"
    assert_equal("cisco123", vtp.password,
                 "Error: vtp password not set")

    vtp.password = ""
    assert_equal("", vtp.password,
                 "Error: vtp default password not set")

    vtp.destroy
  end

  def test_vtp_password_valid
    no_feature_vtp
    vtp = vtp_domain("accounting")
    alphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
    password = ""
    1.upto(Vtp::MAX_VTP_PASSWORD_SIZE - 1) { | i |
      begin
        password += alphabet[i % alphabet.size, 1]
        vtp.password = password
        assert_equal(password.rstrip, vtp.password,
                     "Error: vtp password not set")
      end
    }
    vtp.destroy
  end

  def test_vtp_password_too_long
    no_feature_vtp
    vtp = vtp_domain("accounting")
    password = "a"
    Vtp::MAX_VTP_PASSWORD_SIZE.times {
      password += "a"
    }
    assert_raises(ArgumentError) {
      vtp.password = password
    }
    vtp.destroy
  end

  def test_vtp_filename_nil
    no_feature_vtp
    vtp = vtp_domain("accounting")
    assert_raises(TypeError) do
      vtp.filename = nil
    end
    vtp.destroy
  end

  def test_vtp_filename_valid
    no_feature_vtp
    vtp = vtp_domain("accounting")
    vtp.filename = "bootflash:/test.dat"
    assert_equal("bootflash:/test.dat", vtp.filename,
                 "Error: vtp file content wrong")
    vtp.destroy
  end

  def test_vtp_filename_zero_length
    no_feature_vtp
    vtp = vtp_domain("accounting")
    vtp.filename = vtp.default_filename
    assert_equal(node.config_get_default("vtp", "filename"), vtp.filename,
                 "Error: vtp file content wrong")

    # send in 'no' to remove the config. That will cause the default
    # to get reapplied.
    vtp.filename = ""
    assert_equal(node.config_get_default("vtp", "filename"), vtp.filename,
                 "Error: vtp file content wrong")
    vtp.destroy
  end

  def test_vtp_version_valid
    no_feature_vtp
    vtp = vtp_domain("accounting")
    vtp.version = vtp.default_version
    assert_equal(node.config_get_default("vtp", "version"), vtp.version,
                 "Error: vtp version not default")
    vtp.destroy
  end

  def test_vtp_version3_valid
    no_feature_vtp
    vtp = vtp_domain("accounting")

    ref = cmd_ref.lookup("vtp", "version")
    assert(ref, "Error, reference not found for vtp version3")

    assert_result(ref.test_config_result(3), "Error: vtp version3 error") {
      vtp.version = 3
      vtp.version
    }

    ref = nil
    vtp.destroy
  end

  # Decides whether to check for a raised Exception or an equal value.
  def assert_result(expected_result, err_msg, &block)
    if /Error/ =~ expected_result.to_s
      expected_result = eval(expected_result) if expected_result.is_a?(String)
      assert_raises(expected_result, &block)
    else
      value = block.call
      assert_equal(expected_result, value, err_msg)
    end
  end

  def test_vtp_version_invalid
    no_feature_vtp
    vtp = vtp_domain("accounting")
    assert_raises(Cisco::CliError) do
      vtp.version = 34
    end
    vtp.destroy
  end

  def test_vtp_version_default
    no_feature_vtp
    vtp = vtp_domain("accounting")
    vtp.version = 2
    assert_equal(2, vtp.version,
                 "Error: vtp version not correct")
    vtp.version = vtp.default_version
    assert_equal(node.config_get_default("vtp", "version"), vtp.version,
                 "Error: vtp version not default")
    vtp.destroy
  end

  def test_vtp_feature_enable_disable
    no_feature_vtp
    Vtp.new.enable
    assert(Vtp.enabled, "Error: vtp is not enabled")

    Vtp.new.destroy
    refute(Vtp.enabled, "Error: vtp is not disabled")
  end
end
