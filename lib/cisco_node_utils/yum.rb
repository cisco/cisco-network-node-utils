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
    def self.decompose_name(file_name)
      # ex: chef-12.0.0alpha.2+20150319.git.1.b6f-1.el5.x86_64.rpm
      name_ver_arch_regex = /^([\w\-\+]+)-(\d+\..*)\.(\w{4,})(?:\.rpm)?$/

      # ex n9000_sample-1.0.0-7.0.3.x86_64.rpm
      name_ver_arch_regex_nx = /^(.*)-([\d\.]+-[\d\.]+)\.(\w{4,})\.rpm$/

      # ex: b+z-ip2.x64_64
      name_arch_regex = /^([\w\-\+]+)\.(\w+)$/

      file_name.match(name_ver_arch_regex) ||
        file_name.match(name_ver_arch_regex_nx) ||
        file_name.match(name_arch_regex)
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
      ver = query(query_name)
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
      if "#{platform}" == 'nexus'
        vrf = vrf.nil? ? detect_vrf : "vrf #{vrf}"
        config_set('yum', 'install', pkg, vrf)

        # HACK: The current nxos host installer is a multi-part command
        # which may fail at a later stage yet return a false positive;
        # therefore a post-validation check is needed here to verify the
        # actual outcome.
        validate(pkg)

      elsif "#{platform}" == 'ios_xr'
        filename = pkg.strip.tr(':', '/').split('/').last
        name_arch_regex_xr = /^(.*\d.*-[\d.]*-r\d\d\d\d*.).(\w{4,}).rpm/
        if filename =~ name_arch_regex_xr
          pkg_name = Regexp.last_match(1)
          debug "Installing package #{pkg_name}"
          `ip netns exec default sdr_instcmd install activate \
    pkg 0x0 #{pkg_name}`
          `ip netns exec default sdr_instcmd install commit sdr`
          # debug "#{rc}"
        else
          fail 'Failed to install the requested rpm.'
        end
      end
    end

    # returns version of package, or false if package doesn't exist
    def self.query(pkg, src)
      if "#{platform}" == 'nexus'
        fail TypeError unless pkg.is_a? String
        fail ArgumentError if pkg.empty?
        b = config_get('yum', 'query', pkg)
        fail "Multiple matching packages found for #{pkg}" if b && b.size > 1

      elsif "#{platform}" == 'ios_xr'
        filename = src.strip.tr(':', '/').split('/').last
        name_arch_regex_xr = /^(.*\d.*-[\d.]*-r\d\d\d\d*.).(\w{4,}).rpm/
        if filename =~ name_arch_regex_xr
          pkg_name = Regexp.last_match(1)
          platform = Regexp.last_match(2)
          pkg_name_platform = "#{pkg_name}.#{platform}"
          version = `ip netns exec default sdr_instcmd show install \
                     package #{pkg_name_platform} none | grep -E Version`
          version_var_regex_xr = /^(\s*Version\s*):\s*(\d.*)$/

          version =~ version_var_regex_xr
          ver = Regexp.last_match(2)
          is_active_regex = /^\s*#{pkg_name}/
          is_active = `ip netns exec default sdr_instcmd show install active`
          if is_active =~ is_active_regex
            debug "Package #{pkg_name_platform} version #{ver} is present."
            b = ["#{ver}"]
          end
        end
      end
      b.nil? ? nil : b.first
    end

    def self.remove(pkg, src)
      if "#{platform}" == 'nexus'
        config_set('yum', 'remove', pkg)
      elsif "#{platform}" == 'ios_xr'
        filename = src.strip.tr(':', '/').split('/').last
        name_arch_regex_xr = /^(.*\d.*-[\d.]*-r\d\d\d\d*.).(\w{4,}).rpm-(.*)$/
        if filename =~ name_arch_regex_xr
          pkg_name = Regexp.last_match(1)
          debug "Removing package #{pkg_name}"
          `ip netns exec default sdr_instcmd install \
           deactivate pkg 0x0 #{pkg_name}`
          `ip netns exec default sdr_instcmd install commit sdr`
        end
      end
    end
  end
end
