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
  # This Yum class provides cisco package management functions through nxapi.
  class Yum < NodeUtil
    EXEC_IN_DEFAULT_NS = 'ip netns exec default'
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
      if platform == :nexus
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
      else
        query_name = pkg
        should_ver = pkg.match(/^.*\d.*-([\d.]*)-r\d+.*/)[1]
      end
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
      if platform == :nexus
        vrf = vrf.nil? ? detect_vrf : "vrf #{vrf}"
        config_set('yum', 'install', pkg, vrf)
      else
        # ex pkg => xrv9k-k9sec-1.0.0.0-r61102I
        rc = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd install activate pkg 0x0 \
          #{pkg}`
        Cisco::Logger.debug "install activate #{pkg} : #{rc}"
        rc = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd install commit sdr`
        Cisco::Logger.debug "install commit : #{rc}"
      end
      # post-validation check to verify successful installation.
      validate(pkg)
    end

    # returns version of package, or nil if package doesn't exist
    def self.query(pkg)
      fail TypeError unless pkg.is_a? String
      fail ArgumentError if pkg.empty?
      if platform == :nexus
        b = config_get('yum', 'query', pkg)
        fail "Multiple matching packages found for #{pkg}" if b && b.size > 1
        b.nil? ? nil : b.first
      else
        # Optionally strip the version from package name.
        gr = pkg.match(/^([a-z0-9]+-[a-z0-9]+)(-)?/)
        if gr.nil?
          nil
        else
          active_pkgs_list = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd show \
          install active`
          # Search for package in list of active packages.
          active = active_pkgs_list.match(/^\s*#{gr[1]}-([\d\.]+)/)
          active.nil? ? nil : active[1]
        end
      end
    end

    def self.remove(pkg)
      if platform == :nexus
        config_set('yum', 'remove', pkg)
      else
        # ex pkg => xrv9k-k9sec-1.0.0.0-r61102I
        rc = \
          `#{EXEC_IN_DEFAULT_NS} sdr_instcmd install deactivate pkg 0x0 #{pkg}`
        Cisco::Logger.debug "install deactivate #{pkg} : #{rc}"
        rc = `#{EXEC_IN_DEFAULT_NS} sdr_instcmd install commit sdr`
        Cisco::Logger.debug "install commit sdr : #{rc}"
      end
    end
  end
end
