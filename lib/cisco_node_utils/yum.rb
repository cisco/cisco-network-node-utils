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

    # This function accepts name of the rpm package and returns a match group.
    def self.decompose_name(pkg)
      file_name = pkg.strip.tr(':', '/').split('/').last
      if platform == :nexus
        # ex: chef-12.0.0alpha.2+20150319.git.1.b6f-1.el5.x86_64.rpm
        name_ver_arch_regex = /^([\w\-\+]+)-(\d+\..*)\.(\w{4,})(?:\.rpm)?$/
        # ex n9000_sample-1.0.0-7.0.3.x86_64.rpm
        name_ver_arch_regex_nx = /^(.*)-([\d\.]+-[\d\.]+)\.(\w{4,})\.rpm$/
        # ex: b+z-ip2.x64_64
        name_arch_regex = /^([\w\-\+]+)\.(\w+)$/
        
        file_name.match(name_ver_arch_regex) ||
          file_name.match(name_ver_arch_regex_nx) ||
          file_name.match(name_arch_regex)
      elsif platform == :ios_xr
        # Match group when the rpm is for ios_xr :
        #   1. package name, 2. package version, 3. os version, 4. platform
        # ex xrv9k-k9sec-1.0.0.0-r600.x86_64.rpm-6.0.0
        # xrv9k-k9sec-1.0.0.0-r61102I.x86_64.rpm-XR-DEV-16.02.22C
        name_ver_arch_regex_xr = /^(.*\d.*)-([\d.]*)-(r\d+.*)\.(\w{4,}).rpm/

        file_name.match(name_ver_arch_regex_xr)
      end
    end

    def self.validate(pkg)
      pkg_info = Yum.decompose_name(pkg)
      if pkg_info.nil?
        file_name = pkg.strip.tr(':', '/').split('/').last
        query_name = file_name
      else
        if pkg_info[3].nil?
          query_name = pkg_info[1]
        else
          if platform == :nexus
            query_name = "#{pkg_info[1]}.#{pkg_info[3]}"
          elsif platform == :ios_xr
            # ex query_name xrv9k-k9sec-1.0.0.0-r61102I.x86_64
            query_name = \
              "#{pkg_info[1]}-#{pkg_info[2]}-#{pkg_info[3]}.#{pkg_info[4]}"
          end
        end
      end
      should_ver = pkg_info[2] if pkg_info && pkg_info[3]
      ver = query(query_name)
      Cisco::Logger.debug "Installed package version #{ver}, expected package version" \
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
        pkg_info = Yum.decompose_name(pkg)
        if pkg_info
          # ex pkg_name xrv9k-k9sec-1.0.0.0-r61102I
          pkg_name = "#{pkg_info[1]}-#{pkg_info[2]}-#{pkg_info[3]}"
          Cisco::Logger.debug "Installing package #{pkg_name}"
          rc = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd install activate pkg 0x0 \
          #{pkg_name}`
          Cisco::Logger.debug "install activate #{pkg_name} : #{rc}"
          rc = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd install commit sdr`
          Cisco::Logger.debug "install commit sdr : #{rc}"
        else
          fail "Failed to parse name #{pkg}."
        end
      end
      # post-validation check to verify successful installation.
      validate(pkg)
    end

    # returns version of the package if exists, otherwise returns nil
    def self.query(pkg)
      fail TypeError unless pkg.is_a? String
      fail ArgumentError if pkg.empty?
      if platform == :nexus
        b = config_get('yum', 'query', pkg)
        fail "Multiple matching packages found for #{pkg}" if b && b.size > 1

      elsif platform == :ios_xr
        package_info = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd show install \
                     package #{pkg} none`

        # sample output of show install package
        #     Filename          : xrv9k-k9sec
        #     Version           : 1.0.0.0
        #     Parent Version    : (none)
        #     Platform          : xrv9k
        #     Package Type      : Package
        #   Restart Type      : dependent
        #   Install Method    : parallel
        #   RPM Count         : 1
        #
        #   Package Contents     :
        #     xrv9k-k9sec-1.0.0.0-r61102I.x86_64

        ver_file_regex_xr = /^\s*Filename\s*:\s*(.*)\s*Version\s*:\s*(.*)/

        package_info.match(ver_file_regex_xr)
        filename = Regexp.last_match(1)
        ver = Regexp.last_match(2)
        is_active_regex = /^\s*#{filename}/

        # In XR, even if package is inactive, 'show install package' returns
        # information about the package. Hence we verify if the package is
        # actived
        is_active = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd show install active`
        if is_active =~ is_active_regex
          Cisco::Logger.debug "Package #{filename} version #{ver} is present."
          b = ["#{ver}"]
        end
      end
      b.nil? ? nil : b.first
    end

    def self.remove(pkg)
      fail TypeError unless pkg.is_a? String
      fail ArgumentError if pkg.empty?
      if platform == :nexus
        config_set('yum', 'remove', pkg)
      elsif platform == :ios_xr
        rc = \
          `#{EXEC_IN_DEFAULT_NS} sdr_instcmd install deactivate pkg 0x0 #{pkg}`
        Cisco::Logger.debug "install deactivate #{pkg} : #{rc}"
        rc = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd install commit sdr`
        Cisco::Logger.debug "install commit sdr : #{rc}"
      end
    end
  end
end
