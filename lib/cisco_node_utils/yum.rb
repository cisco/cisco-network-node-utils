#
# NXAPI implementation of Yum class
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

require File.join(File.dirname(__FILE__), 'node')

module Cisco
  # This Yum class provides cisco package management functions through nxapi.
  class Yum
    @@node = Cisco::Node.instance

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
      file_name = pkg.strip.gsub(':', '/').split('/').last
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
        raise "Failed to install the requested rpm"
      end
    end

    def self.get_vrf
      # Detect current namespace from agent environment
      inode = File::Stat.new("/proc/self/ns/net").ino
      # -L reqd for guestshell's find command
      vrfname = File.basename(`find -L /var/run/netns/ -inum #{inode}`.chop)
      vrf = "vrf " + vrfname unless vrfname.empty?
      vrf
    end

    def self.install(pkg, vrf = nil)
      vrf = vrf.nil? ? get_vrf : "vrf #{vrf}"
      @@node.config_set("yum", "install", pkg, vrf)

      # HACK: The current nxos host installer is a multi-part command
      # which may fail at a later stage yet return a false positive;
      # therefore a post-validation check is needed here to verify the
      # actual outcome.
      validate(pkg)
    end

    # returns version of package, or false if package doesn't exist
    def self.query(pkg)
      raise TypeError unless pkg.is_a? String
      raise ArgumentError if pkg.empty?
      b = @@node.config_get("yum", "query", pkg)
      raise "Multiple matching packages found for #{pkg}" if b and b.size > 1
      b.nil? ? nil : b.first
    end

    def self.remove(pkg)
      @@node.config_set("yum", "remove", pkg)
    end
  end
end
