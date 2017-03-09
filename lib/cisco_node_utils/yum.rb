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
    def self.validate_installed(pkg)
      # Sample data returned from config_get('yum', 'query_all')
      # ["nxos.sample-n8k_EOR.lib32_nxos", "1.0.0-7.0.3.F1.1", "@patching"],
      patch_data = config_get('yum', 'query_all')
      patch_data.each do |name_arch, version, _state|
        # Separate name and architecture
        next if name_arch.rindex('.').nil?
        arch = name_arch.slice!(name_arch.rindex('.')..-1).delete('.')
        # Version/Architecture info not available when only pkg name specified.
        version = arch = '' if name_arch == pkg
        # Check for match
        if pkg.match(name_arch) && pkg.match(version) && pkg.match(arch)
          return true
        end
      end
      fail 'Failed to install the requested rpm'
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
      vrf = vrf.nil? ? detect_vrf : "vrf #{vrf}"

      begin
        config_set('yum', 'install', pkg, vrf)

        # HACK: The current nxos host installer is a multi-part command
        # which may fail at a later stage yet return a false positive;
        # therefore a post-validation check is needed here to verify the
        # actual outcome.
        validate_installed(pkg)
      rescue Cisco::CliError, RuntimeError => e
        raise Cisco::CliError, "#{e.class}, #{e.message}"
      end
    end

    # returns version of package, or false if package doesn't exist
    def self.query(pkg)
      fail TypeError unless pkg.is_a? String
      fail ArgumentError if pkg.empty?
      b = config_get('yum', 'query', pkg)
      fail "Multiple matching packages found for #{pkg}" if b && b.size > 1
      b.nil? ? nil : b.first
    end

    def self.remove(pkg)
      config_set('yum', 'deactivate', pkg)
      # May not be able to remove the package immediately after
      # deactivation.
      while (try ||= 1) < 20
        o = config_set('yum', 'remove', pkg)
        break unless o[/operation is in progress, please try again later/]
        sleep 1
        try += 1
      end
    end
  end
end
