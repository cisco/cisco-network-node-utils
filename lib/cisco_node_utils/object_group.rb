#
# May 2017, Sai Chintalapudi
#
# Copyright (c) 2017 Cisco and/or its affiliates.
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
require_relative 'acl'

module Cisco
  # node_utils class for object_group
  class ObjectGroup < NodeUtil
    attr_reader :afi, :type, :grp_name

    def initialize(afi, type, name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless type[/address|port/]
      @afi = Acl.afi_cli(afi)
      @type = type
      @grp_name = name

      set_args_keys_default
      create if instantiate
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = { afi: @afi, type: @type, grp_name: @grp_name }
      @get_args = @set_args
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    def create
      config_set('object_group', 'create', @set_args)
    end

    def destroy
      config_set('object_group', 'destroy', @set_args)
    end

    def ==(other)
      grp_name == other.grp_name && afi == other.afi && type == other.type
    end

    def self.object_groups
      hash = {}
      grps = config_get('object_group', 'all_object_groups')
      return hash if grps.nil?
      grps.each do |afi, type, name|
        lafi = afi
        lafi = 'ipv4' if afi == 'ip'
        hash[lafi] ||= {}
        hash[lafi][type] ||= {}
        hash[lafi][type][name] = ObjectGroup.new(lafi, type, name, false)
      end
      hash
    end
  end # class
end # module
