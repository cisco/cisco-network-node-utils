#
# NXAPI implementation of Interface class
#
# November 2015, Deepak Cherian
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

require File.join(File.dirname(__FILE__), 'node_utils')

# TBD
module Features
  def self.included(base)
    base.extend(ClassMethods)
  end

  # TBD
  module ClassMethods
    # @@node = Cisco::Node.instance
    # debug "@@@@@ Loaded Features node is #{@@node}"

    def fabricpath_feature
      debug "In Features node is #{@@node}"
      fabricpath = config_get('fabricpath', 'feature')
      fail 'fabricpath_feature not found' if fabricpath.nil?
      return :disabled if fabricpath.nil?
      fabricpath.shift.to_sym
    end

    def fabricpath_feature_set(fabricpath_set)
      curr = fabricpath_feature
      return if curr == fabricpath_set

      case fabricpath_set
      when :enabled
        config_set('fabricpath', 'feature_install', '') if curr == :uninstalled
        config_set('fabricpath', 'feature', '')
      when :disabled
        config_set('fabricpath', 'feature', 'no') if curr == :enabled
        return
      when :installed
        config_set('fabricpath', 'feature_install', '') if curr == :uninstalled
      when :uninstalled
        config_set('fabricpath', 'feature', 'no') if curr == :enabled
        config_set('fabricpath', 'feature_install', 'no')
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def vni_feature
      debug "In Features node is #{@@node}"
      vni = config_get('vni', 'feature')
      fail 'vni feature not found' if vni.nil?
      return :disabled if vni.nil?
      vni.first.to_sym
    end

    def vni_feature_set(vni_set)
      curr = vni_feature
      return if curr == vni_set

      case vni_set
      when :enabled
        config_set('vni', 'feature', '')
      when :disabled
        config_set('vni', 'feature', 'no') if curr == :enabled
        return
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def vxlan_feature
      debug "In Features node is #{@@node}"
      vxlan = config_get('vxlan', 'feature')
      fail 'vxlan/nv_overlay feature not found' if vxlan.nil?
      return :disabled if vxlan.nil?
      vxlan.first.to_sym
    end

    def vxlan_feature_set(vxlan_set)
      curr = vxlan_feature
      return if curr == vxlan_set

      case vxlan_set
      when :enabled
        config_set('vxlan', 'feature', '')
      when :disabled
        config_set('vxlan', 'feature', 'no') if curr == :enabled
        return
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def pim_feature
      debug "In Features node is #{@@node}"
      pim = config_get('pim', 'feature')
      fail 'pim feature not found' if pim.nil?
      return :disabled if pim.nil?
      pim.first.to_sym
    end

    def pim_feature_set(pim_set)
      curr = pim_feature
      return if curr == pim_set

      case pim_set
      when :enabled
        config_set('pim', 'feature', '')
      when :disabled
        config_set('pim', 'feature', 'no') if curr == :enabled
        return
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end
  end # end of module ClassMethods
end # end of module Features
