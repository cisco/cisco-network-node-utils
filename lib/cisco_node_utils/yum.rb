#
# NXAPI implementation of Yum class
#
# April 2015, Alex Hunsberger
#
# March 2017, Re-written by Mike Wiebe
#
# Copyright (c) 2015-2017 Cisco and/or its affiliates.
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
require_relative 'logger'

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
        # get package name first
        name = pkg_name(pkg)
        # call remove if pkg exists
        remove(name) unless name.empty?
        add(pkg, vrf)
        activate(pkg)
        commit(pkg_name(pkg))
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
      # get committed state
      cstate = query_committed(pkg)
      # get activated state
      astate = query_activated(pkg)

      if astate && cstate
        # pkg is active and committed
        # so deactivate, commit and remove
        deactivate(pkg)
        commit_deactivate(pkg)
        delete(pkg)
      elsif cstate
        # pkg is inactive and committed
        # so commit and remove
        commit_deactivate(pkg)
        delete(pkg)
      elsif astate
        # pkg is active and not committed
        # so deactivate and remove
        deactivate(pkg)
        delete(pkg)
      else
        # pkg is inactive and not committed
        # so just remove
        delete(pkg)
      end
    rescue Cisco::CliError, RuntimeError => e
      raise Cisco::CliError, "#{e.class}, #{e.message}"
    end

    def self.add(pkg, vrf=nil)
      try_operation('add', pkg, vrf)
      while (try ||= 1) < 20
        return if query_added(pkg)
        sleep 1
        try += 1
      end
      fail "Failed to add pkg: #{pkg}, using vrf #{vrf}"
    end

    def self.activate(pkg)
      try_operation('activate', pkg)
      while (try ||= 1) < 20
        return if query_activated(pkg)
        sleep 1
        try += 1
      end
      fail "Failed to activate pkg: #{pkg}"
    end

    def self.commit(pkg)
      try_operation('commit', pkg)
      while (try ||= 1) < 20
        return if query_committed(pkg)
        sleep 1
        try += 1
      end
      fail "Failed to commit pkg: #{pkg}"
    end

    def self.commit_deactivate(pkg)
      try_operation('commit', pkg)
      while (try ||= 1) < 20
        return unless query_committed(pkg)
        sleep 1
        try += 1
      end
      fail "Failed to commit after deactivate pkg: #{pkg}"
    end

    def self.deactivate(pkg)
      try_operation('deactivate', pkg)
      while (try ||= 1) < 20
        return if query_inactive(pkg)
        sleep 1
        try += 1
      end
      fail "Failed to deactivate pkg: #{pkg}"
    end

    def self.delete(pkg)
      try_operation('remove', pkg)
      while (try ||= 1) < 20
        return if query_removed(pkg)
        sleep 1
        try += 1
      end
      fail "Failed to delete pkg: #{pkg}"
    end

    def self.try_operation(operation, pkg, vrf=nil)
      args = vrf.nil? ? { pkg: pkg } : { pkg: pkg, vrf: vrf }
      while (try ||= 1) < 20
        o = config_set('yum', operation, args)
        break unless o[/Another install operation is in progress/]
        sleep 1
        try += 1
      end
    end

    def self.pkg_name(pkg)
      config_get('yum', 'pkg_name', pkg: pkg)
    end

    def self.query_activated(pkg)
      config_get('yum', 'query_activated', pkg: pkg)
    end

    def self.query_added(pkg)
      config_get('yum', 'query_added', pkg: pkg)
    end

    def self.query_committed(pkg)
      o = config_get('yum', 'query_committed', pkg: pkg)
      return false if o.nil?
      o.include? pkg
    end

    def self.query_inactive(pkg)
      config_get('yum', 'query_inactive', pkg: pkg)
    end

    def self.query_removed(pkg)
      val = config_get('yum', 'query_removed', pkg: pkg)
      val ? false : true
    end

    def self.query_state(pkg)
      config_get('yum', 'query_state', pkg: pkg).downcase
    end
  end
end
