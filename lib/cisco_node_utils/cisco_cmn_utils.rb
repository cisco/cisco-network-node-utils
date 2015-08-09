# Common Utilities for Puppet Resources.
#
# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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

module Cisco
  # global constants
  DEFAULT_INSTANCE_NAME = 'default'

  class Encryption
    # password encryption types
    def Encryption.cli_to_symbol(cli)
      case cli
      when "0", 0
        :cleartext
      when "3", 3
        :"3des"        # yuck :-(
      when "5", 5
        :md5
      when "6", 6
        :aes
      when "7", 7
        :cisco_type_7
      else
        raise KeyError
      end
    end

    def Encryption.symbol_to_cli(symbol)
      symbol = symbol.downcase if symbol.is_a? String
      case symbol
      when :cleartext, :none, "cleartext", "none", "0", 0
        "0"
      when :"3des", "3des", "3", 3
        "3"
      when :md5, "md5", "5", 5
        "5"
      when :aes, "aes", "6", 6
        "6"
      when :cisco_type_7, :type_7, "cisco_type_7", "type_7", "7", 7
        "7"
      else
        raise KeyError
      end
    end
  end

  class ChefUtils
    def ChefUtils.generic_prop_set(klass, rlbname, props)
      props.each do |prop|
        klass.instance_eval {
          # Helper Chef setter method, e.g.:
          #   if @new_resource.foo.nil?
          #     def_prop = @rlb.default_foo
          #     @new_resource.foo(def_prop)
          #   end
          #   current = @rlb.foo
          #   if current != @new_resource.foo
          #     converge_by("update foo '#{current}' => " +
          #                 "'#{@new_resource.foo}'") do
          #       @rlb.foo=(@new_resource.foo)
          #     end
          #   end
          if @new_resource.send(prop).nil?
            def_prop = instance_variable_get(rlbname).send("default_#{prop}")
            # Set resource to default if recipe property is not specified
            @new_resource.send(prop, def_prop)
          end
          current = instance_variable_get(rlbname).send(prop)
          if current != @new_resource.send(prop)
            converge_by("update #{prop} '#{current}' => " +
                        "'#{@new_resource.send(prop)}'") do
              instance_variable_get(rlbname).send("#{prop}=",
                                                       @new_resource.send(prop))
            end
          end
        }
      end
    end
  end # class ChefUtils
end   # module Cisco
