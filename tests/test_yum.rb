# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/yum'
require_relative '../lib/cisco_node_utils/platform'

# TestYum - Minitest for Yum node utility class
class TestYum < CiscoTestCase
  # rubocop:disable Style/ClassVars
  @@skip = false
  @@run_setup = true
  # rubocop:enable Style/ClassVars

  @skip_unless_supported = 'yum'

  def select_pkg
    # rubocop:disable Style/ClassVars
    @@pv = Platform.image_version
    case @@pv
    when /7.0\(3\)I2\(1\)/
      info 'Testing Patch For Camden Release Image'
      @@pkg_filename = 'n9000_sample-1.0.0-7.0.3.x86_64.rpm'
      @@pkg = 'n9000_sample'
      @@pkg_ver = '1.0.0-7.0.3'
    when /7.0\(3\)I3\(1\)/
      info 'Testing Patch For Dublin Release Image'
      @@pkg_filename = 'CSCuxdublin-1.0.0-7.0.3.I3.1.lib32_n9000.rpm'
      @@pkg = 'CSCuxdublin'
      @@pkg_ver = '1.0.0-7.0.3.I3.1'
    when /7.0\(4\)I4\(1\)/
      # TBD: Add Dublin Plus RPM when it becomes available.
      # info 'Testing Patch For Dublin Plus Release Image'
    else
      skip "Available patches are not compatible with this image: #{@@pv}"
    end
    @@incompatible_rpm_msg =
      ": Sample rpm is compatible with NX-OS release version #{@@pv}."  \
      'This test may fail with other versions.'
    # rubocop:enable Style/ClassVars
  end

  def setup
    super
    # only run check once (can't use initialize because @device isn't ready)
    return unless @@run_setup

    select_pkg
    s = @device.cmd("show file bootflash:#{@@pkg_filename} cksum")
    if s[/No such file/]
      @@skip = true # rubocop:disable Style/ClassVars
    else
      # add pkg to the repo
      # normally this could be accomplished by first installing via full path
      # but that would make these tests order dependent

      # Remnants of the package my still exist from a previous install attempt.
      info 'Executing test setup... Please be patient, this will take a while.'
      steps = ["install deactivate #{@@pkg}", "install commit #{@@pkg}",
               "install remove #{@@pkg} forced",
               "install add bootflash:#{@@pkg_filename}"]
      steps.each do |step|
        info "Executing setup step: #{step}..."
        s = @device.cmd(step)
        sleep 20
        debug "Step Complete.\n\n#{s}\n"
      end
    end
    @@run_setup = false # rubocop:disable Style/ClassVars
  end

  def skip?
    skip "file bootflash:#{@@pkg_filename} is required. " \
      'this file can be found in the cisco_node_utils/tests directory' if @@skip
  end

  def test_install_remove
    skip?
    if @device.cmd("show install package | include #{@@pkg}")[/@patching/]
      @device.cmd("install deactivate #{@@pkg}")
      node.cache_flush
      sleep 20
    end

    # On dublin and later images, must specify the full rpm name.
    package = @@pv[/7.0\(3\)I2\(1\)/] ? @@pkg : @@pkg_filename
    # Specify "management" vrf for install
    Yum.install(package, 'management')
    sleep 20
    assert(Yum.query(@@pkg), "failed to find installed package #{@@pkg}")

    Yum.remove(package)
    sleep 20
    refute_show_match(command: "show install package | include #{@@pkg}",
                      pattern: /@patching/)
  rescue RuntimeError => e
    assert(false, e.message + @@incompatible_rpm_msg)
  end

  def test_ambiguous_package_error
    skip?
    assert_raises(RuntimeError) { Yum.query('busybox') }
  end

  def test_package_does_not_exist_error
    assert_raises(Cisco::CliError) do
      Yum.install('bootflash:this_is_not_real.rpm', 'management')
    end
    assert_raises(RuntimeError) do
      Yum.install('also_not_real', 'management')
    end
  end

  def test_query
    skip?
    unless @device.cmd("show install package | include #{@@pkg}")[/@patching/]
      @device.cmd("install activate #{@@pkg}")
      node.cache_flush
      sleep 20
    end
    ver = Yum.query(@@pkg)
    assert_equal(ver, @@pkg_ver, @@incompatible_rpm_msg)
    @device.cmd("install deactivate #{@@pkg}")
    node.cache_flush
    sleep 20
    ver = Yum.query(@@pkg)
    assert_nil(ver)
  end
end
