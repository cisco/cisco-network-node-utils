# Common Utilities for Puppet Resources.
#
# Copyright (c) 2014-2016 Cisco and/or its affiliates.
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

# Add some general-purpose constants and APIs to the Cisco namespace
module Cisco
  # global constants
  DEFAULT_INSTANCE_NAME = 'default'

  # Encryption - helper class for translating encryption type CLI
  class Encryption
    # password encryption types
    def self.cli_to_symbol(cli)
      case cli
      when '0', 0, 'clear'
        :cleartext
      when '3', 3
        :"3des" # yuck :-(
      when '5', 5, 'encrypted'
        :md5
      when '6', 6
        :aes
      when '7', 7
        :cisco_type_7
      else
        fail KeyError
      end
    end

    def self.symbol_to_cli(symbol)
      symbol = symbol.downcase if symbol.is_a? String
      case symbol
      when :cleartext, :none, 'cleartext', 'none', '0', 0
        '0'
      when :"3des", '3des', '3', 3
        '3'
      when :md5, 'md5', '5', 5
        '5'
      when :aes, 'aes', '6', 6
        '6'
      when :cisco_type_7, :type_7, 'cisco_type_7', 'type_7', '7', 7
        '7'
      else
        fail KeyError
      end
    end
  end

  # ChefUtils - helper class for Chef code generation
  class ChefUtils
    def self.generic_prop_set(klass, rlbname, props)
      props.each do |prop|
        klass.instance_eval do
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
            converge_by("update #{prop} '#{current}' => " \
                        "'#{@new_resource.send(prop)}'") do
              instance_variable_get(rlbname).send("#{prop}=",
                                                  @new_resource.send(prop))
            end
          end
        end
      end
    end
  end # class ChefUtils

  # General utility class
  class Utils
    require 'ipaddr'

    # Helper utility to check for older Nexus I2 images
    def self.nexus_i2_image
      require_relative 'platform'
      true if Platform.image_version[/7.0.3.I2/]
    end

    def self.image_version?(ver_regexp)
      require_relative 'platform'
      return true if Platform.image_version[ver_regexp]
    end

    def self.chassis_pid?(ver_regexp)
      require_relative 'platform'
      return true if Platform.chassis['pid'][ver_regexp]
    end

    # Helper utility method for ip/prefix format networks.
    # For ip/prefix format '1.1.1.1/24' or '2000:123:38::34/64',
    # we need to mask the address using the prefix length so that they
    # are converted to '1.1.1.0/24' or '2000:123:38::/64'
    def self.process_network_mask(network)
      mask = network.split('/')[1]
      address = IPAddr.new(network).to_s
      network = address + '/' + mask unless mask.nil?
      network
    end

    # Helper to build a hash of add/remove commands for a nested array.
    # Useful for network, redistribute, etc.
    #   should: an array of expected cmds (manifest/recipe)
    #  current: an array of existing cmds on the device
    def self.depth(a)
      return 0 unless a.is_a?(Array)
      1 + depth(a[0])
    end

    def self.delta_add_remove(should, current=[], opt=nil)
      current = [] if current.nil?
      should = [] if should.nil?

      # Remove nil entries from array
      should.each(&:compact!) if depth(should) > 1
      delta = { add: should - current, remove: current - should }

      # Some cli properties cannot be updated, thus must be removed first
      return delta if opt == :updates_not_allowed

      # Delete entries from :remove if f1 is an update to an existing command
      delta[:add].each do |id, _|
        # Differentiate between comparing nested and unnested arrays by
        # checking the depth of the array.
        if depth(should) == 1
          delta[:remove].delete_if { |f1| [f1] if f1.to_s == id.to_s }
        else
          delta[:remove].delete_if { |f1, f2| [f1, f2] if f1.to_s == id.to_s }
        end
      end
      delta
    end # delta_add_remove

    def self.length_to_bitmask(length)
      IPAddr.new('255.255.255.255').mask(length).to_s
    end

    def self.bitmask_to_length(bitmask)
      # Convert bitmask to a 32-bit integer,
      # convert that to binary, and count the 1s
      IPAddr.new(bitmask).to_i.to_s(2).count('1')
    rescue IPAddr::InvalidAddressError => e
      raise ArgumentError, "bitmask '#{bitmask}' is not valid: #{e}"
    end

    # Helper to 0-pad a mac address.
    def self.zero_pad_macaddr(mac)
      return nil if mac.nil? || mac.empty?
      o1, o2, o3 = mac.split('.').map { |o| o.to_i(16).to_s(10) }
      sprintf('%04x.%04x.%04x', o1, o2, o3)
    end

    # For spanning tree range based parameters, the range
    # is very dynamic and so before the parameters are set,
    # the rest of the range needs to be reset
    # For ex: if the ranges 2-42 and 83-200 are getting set,
    # and the total range of the given parameter is 1-4000
    # then 1,43-82,201-4000 needs to be reset. This method
    # takes the set ranges and gives back the range to be reset
    def self.get_reset_range(total_range, remove_ranges)
      fail 'invalid range' unless total_range.include?('-')
      return total_range if remove_ranges.empty?

      trs = total_range.gsub('-', '..')
      tra = trs.split('..').map { |d| Integer(d) }
      tr = tra[0]..tra[1]
      tarray = tr.to_a
      remove_ranges.each do |rr, _val|
        rarray = rr.gsub('-', '..').split(',')
        rarray.each do |elem|
          if elem.include?('..')
            elema = elem.split('..').map { |d| Integer(d) }
            ele = elema[0]..elema[1]
            tarray -= ele.to_a
          else
            tarray.delete(elem.to_i)
          end
        end
      end
      Utils.array_to_str(tarray)
    end

    # This method converts an array to string form
    # for ex: if the array has 1, 2 to 10, 83 to 2014, 3022
    # and the string will be "1,2-10,83-2014,3022"
    def self.array_to_str(array, sort=true)
      farray = sort ? array.compact.uniq.sort : array.compact
      lranges = []
      unless farray.empty?
        l = array.first
        r = nil
        farray.each do |aelem|
          if r && aelem != r.succ
            if l == r
              lranges << l
            else
              lranges << Range.new(l, r)
            end
            l = aelem
          end
          r = aelem
        end
        if l == r
          lranges << l
        else
          lranges << Range.new(l, r)
        end
      end
      lranges.to_s.gsub('..', '-').delete('[').delete(']').delete(' ')
    end

    # normalize_range_array
    #
    # Given a list of ranges, merge any overlapping ranges and sort them.
    #
    # Note: The ranges are converted to ruby ranges for easy merging,
    # then converted back to a cli-syntax range.
    #
    # Accepts an array or string:
    #   ["2-5", "9", "4-6"]  -or-  '2-5, 9, 4-6'  -or-  ["2-5, 9, 4-6"]
    # Returns a merged and ordered range as an array or string:
    #   ["2-6", "9"] -or- '2-6,9'
    #
    def self.normalize_range_array(range, fmt=:array)
      return range if range.nil? || range.empty?
      range = range.clone

      # Handle string within an array: ["2-5, 9, 4-6"] to '2-5, 9, 4-6'
      range = range.shift if range.is_a?(Array) && range.length == 1

      # Handle string only: '2-5, 9, 4-6' to ["2-5", "9", "4-6"]
      range = range.split(',') if range.is_a?(String)

      # Convert to ruby-syntax ranges
      range = dash_range_to_ruby_range(range)

      # Sort & Merge
      merged = merge_range(range)

      # Convert back to cli dash-syntax
      merged_array = ruby_range_to_dash_range(merged)

      return merged_array.join(',') if fmt == :string
      merged_array
    end

    # Convert a cli-dash-syntax range to ruby-range. This is useful for
    # preparing inputs to merge_range().
    #
    # Inputs an array or string of dash-syntax ranges -> returns an array
    # of ruby ranges.
    #
    # Accepts an array or string: ["2-5", "9", "4-6"] or '2-5, 9, 4-6'
    # Returns an array of ranges: [2..5, 9..9, 4..6]
    #
    def self.dash_range_to_ruby_range(range)
      range = range.split(',') if range.is_a?(String)
      range.map! do |rng|
        if rng[/-/]
          # '2-5' -> 2..5
          rng.split('-').inject { |a, e| a.to_i..e.to_i }
        else
          # '9' -> 9..9
          rng.to_i..rng.to_i
        end
      end
      range
    end

    # Convert a ruby-range to cli-dash-syntax.
    #
    # Inputs an array of ruby ranges -> returns an array or string of
    # dash-syntax ranges.
    #
    # when (:array)  [2..6, 9..9]  ->  ['2-6', '9']
    #
    # when (:string)  [2..6, 9..9]  ->  '2-6, 9'
    #
    def self.ruby_range_to_dash_range(range, type=:array)
      fail unless range.is_a?(Array)
      range.map! do |r|
        if r.first == r.last
          # 9..9 -> '9'
          r.first.to_s
        else
          # 2..6 -> '2-6'
          r.first.to_s + '-' + r.last.to_s
        end
      end
      return range.join(', ') if type == :string
      range
    end

    # Convert a dash-range set into individual elements.
    # This is useful for preparing inputs to delta_add_remove().
    #
    # Inputs an array or string of dash-ranges:
    #  ["2-5", "9", "4-6"] or '2-5, 9, 4-6' or ['2-5, 9, 4-6']
    # Returns an array of range elements:
    #  ["2", "3", "4", "5", "6", "9"]
    #
    def self.dash_range_to_elements(range)
      return [] if range.nil?
      range = range.shift if range.is_a?(Array) && range.length == 1
      range = range.split(',') if range.is_a?(String)

      final = []
      range = dash_range_to_ruby_range(range)
      range.each do |rng|
        # 2..5 maps to ["2", "3", "4", "5"]
        final << rng.map(&:to_s)
      end
      final.flatten.uniq.sort
    end

    # Merge overlapping ranges.
    #
    # Inputs an array of ruby ranges:         [2..5, 9..9, 4..6]
    # Returns an array of merged ruby ranges: [2..6, 9..9]
    #
    def self.merge_range(range)
      # sort to lowest range 'first' values:
      #    [2..5, 9..9, 4..6]  ->  [2..5, 4..6, 9..9]
      range = range.sort_by(&:first)

      *merged = range.shift
      range.each do |r|
        lastr = merged[-1]
        if lastr.last >= r.first - 1
          merged[-1] = lastr.first..[r.last, lastr.last].max
        else
          merged.push(r)
        end
      end
      merged
    end # merge_range

    def self.add_quotes(value)
      return value if image_version?(/7.3.0/)
      value = "\"#{value}\"" unless
        value.start_with?('"') && value.end_with?('"')
      value
    end # add_quotes
  end # class Utils
end   # module Cisco
