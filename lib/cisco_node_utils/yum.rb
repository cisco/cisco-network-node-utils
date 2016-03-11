#
# NXAPI implementation of Yum class
#
# April 2015, Alex Hunsberger
#
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

require_relative 'node_util'

module Cisco
  # This Yum class provides cisco package management functions.
  class Yum < NodeUtil
    EXEC_IN_DEFAULT_NS = 'ip netns exec default'

    # This function accepts name of the rpm package and returns match
    # group - 1. package name, 2. package version, 3. os version, 4. platform
    def self.decompose_name(file_name)
      # ex: chef-12.0.0alpha.2+20150319.git.1.b6f-1.el5.x86_64.rpm
      name_ver_arch_regex = /^([\w\-\+]+)-(\d+\..*)\.(\w{4,})(?:\.rpm)?$/

      # ex n9000_sample-1.0.0-7.0.3.x86_64.rpm
      name_ver_arch_regex_nx = /^(.*)-([\d\.]+-[\d\.]+)\.(\w{4,})\.rpm$/

      # ex: b+z-ip2.x64_64
      name_arch_regex = /^([\w\-\+]+)\.(\w+)$/

      # xrv9k-k9sec-1.0.0.0-r600.x86_64.rpm-6.0.0
      # xrv9k-k9sec-1.0.0.0-r61102I.x86_64.rpm-XR-DEV-16.02.22C
      name_ver_arch_regex_xr = /^(.*\d.*)-([\d.]*)-(r\d+.*)\.(\w{4,}).rpm/

      if platform == :nexus
        file_name.match(name_ver_arch_regex) ||
          file_name.match(name_ver_arch_regex_nx) ||
          file_name.match(name_arch_regex)
      elsif platform == :ios_xr
        file_name.match(name_ver_arch_regex_xr)
      end
    end

    def self.validate(pkg)
      file_name = pkg.strip.tr(':', '/').split('/').last
      pkg_info = Yum.decompose_name(file_name)
      if pkg_info.nil?
        query_name = file_name
      else
        if pkg_info[3].nil?
          query_name = pkg_info[1]
        else
          query_name = "#{pkg_info[1]}.#{pkg_info[3]}"
        end
      end
      should_ver = pkg_info[2] if pkg_info && pkg_info[3]
      ver = query(query_name, pkg)
      debug "Installed package version #{ver}, expected package version" \
            "#{should_ver}"
      if ver.nil? || (!should_ver.nil? && should_ver != ver)
        fail 'Failed to install the requested rpm'
      end
    end

    def self.detect_vrf
      # Detect current namespace from agent environment
      inode = File::Stat.new('/proc/self/ns/net').ino
      # -L reqd for guestshell's find command
      vrfname = File.basename(`find -L /var/run/netns/ -inum #{inode}`.chop)
      vrf = 'vrf ' + vrfname unless vrfname.empty?
      vrf
    end

    def self.install(pkg, vrf=nil)
      if platform == :nexus
        vrf = vrf.nil? ? detect_vrf : "vrf #{vrf}"
        config_set('yum', 'install', pkg, vrf)

      elsif platform == :ios_xr
        filename = pkg.strip.tr(':', '/').split('/').last
        pkg_info = Yum.decompose_name(filename)
        if pkg_info
          pkg_name = "#{pkg_info[1]}-#{pkg_info[2]}-#{pkg_info[3]}"
          debug "Installing package #{pkg_name}"
          rc = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd install activate pkg 0x0 \
          #{pkg_name}`
          debug "install activate #{pkg_name} : #{rc}"
          rc = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd install commit sdr`
          debug "install commit sdr : #{rc}"
        end
      end
      # post-validation check to verify the outcome.
      validate(pkg)
    end

    # returns version of package, or false if package doesn't exist
    def self.query(pkg, src)
      if platform == :nexus
        fail TypeError unless pkg.is_a? String
        fail ArgumentError if pkg.empty?
        b = config_get('yum', 'query', pkg)
        fail "Multiple matching packages found for #{pkg}" if b && b.size > 1

      elsif platform == :ios_xr
        filename = src.strip.tr(':', '/').split('/').last
        pkg_info = Yum.decompose_name(filename)
        pkg_name = pkg_info[1]
        should_version = pkg_info[2]
        xr_version = pkg_info[3]
        platform_var = pkg_info[4]
        query_package_name = "#{pkg_name}-#{should_version}" \
                            "-#{xr_version}.#{platform_var}"

        version = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd show install \
                     package #{query_package_name} none | grep -E Version`
        version_var_regex_xr = /^(\s*Version\s*):\s*(\d.*)$/

        version.match(version_var_regex_xr)
        ver = Regexp.last_match(2)
        is_active_regex = /^\s*#{pkg_name}/
        is_active = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd show install active`
        if is_active =~ is_active_regex
          debug "Package #{query_package_name} version #{ver} is present."
          b = ["#{ver}"]
        end
      end
      b.nil? ? nil : b.first
    end

    def self.remove(pkg, src)
      if platform == :nexus
        config_set('yum', 'remove', pkg)
      elsif platform == :ios_xr
        filename = src.strip.tr(':', '/').split('/').last
        pkg_info = Yum.decompose_name(filename)
        if pkg_info
          pkg_name = "#{pkg_info[1]}-#{pkg_info[2]}-#{pkg_info[3]}"
          debug "Removing package #{pkg_name}"
          rc = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd install deactivate pkg 0x0 \
          #{pkg_name}`
          debug "install deactivate #{pkg_name} : #{rc}"
          rc = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd install commit sdr`
          debug "install commit sdr : #{rc}"
        end
      end
    end
  end
end
