# June 2016, Charles Burkett
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

require 'json'

module Cisco
  # class Cisco::Yang
  # Utility class mainly containing methods to compare YANG configurations
  # in order to determine if the running config is in-sync with the
  # desired config.
  class Yang
    # Is the specified yang string empty?
    def self.empty?(yang)
      !yang || yang.empty?
    end

    # Given target and current YANG configurations, returns true if
    # the configurations are in-sync, relative to a "merge_config" action
    # @param should [String] the should configuration in YANG JASON format
    # @param is [String] the is configuration in YANG JASON format
    def self.insync_for_merge?(should, is)
      should_hash = self.empty?(should) ? {} : JSON.parse(should)
      is_hash = self.empty?(is) ? {} : JSON.parse(is)

      !needs_something?(:merge, should_hash, is_hash)
    end

    # Given a is and should YANG configuration, returns true if
    # the configuration are in-sync, relative to a "replace_config" action
    # @param should [String] the should configuration in YANG JASON format
    # @param is [String] the is configuration in YANG JASON format
    def self.insync_for_replace?(should, is)
      should_hash = self.empty?(should) ? {} : JSON.parse(should)
      is_hash = self.empty?(is) ? {} : JSON.parse(is)

      !needs_something?(:replace, should_hash, is_hash)
    end

    # usage:
    #   needs_something?(op, should, run)
    #
    #   op     - symbol - If value is not :replace, it's assumed to be :merge.
    #                     Indicates to the function whether to check for a
    #                     possible merge vs. replace
    #
    #   should - JSON   - JSON tree representing target configuration
    #
    #   is     - JSON   - JSON tree representing current configuration
    #
    #
    # Needs merge will determine if should and is differ
    # sufficiently to necessitate running the merge command.
    #
    # The logic here amounts to determining if should is a subtree
    # of is, with a tiny bit of domain trickiness surrounding
    # elements that are arrays that contain a single nil element
    # that is required for "creating" certain configuration elements.
    #
    # There are ultimately 3 different types of elements in a json
    # tree.  Hashes, Arrays, and leaves.  While hashes and array values
    # are organized with an order, the logic here ignores the order.
    # In fact, it specifically attempts to match assuming order
    # doesn't matter.  This is largely to allow users some freedom
    # in specifying the target configuration.  The gRPC interface
    # doesn't seem to care about order.  If that changes, then so
    # should this code.
    #
    # Arrays and Hashes are compared by iterating over every element
    # in should, and ensuring it is within is.
    #
    # Leaves are directly compared for equality, excepting the
    # condition that the should leaf is in fact an array with one
    # element that is nil.
    #
    # Needs replace will determine if should and is differ
    # sufficiently to necessitate running the replace command.
    #
    # The logic is the same as merge, except when comparing
    # hashes, if the is hash table has elements that are not
    # in should, we ultimately indicate that replace is needed
    def self.needs_something?(op, should, is)
      !hash_equiv?(op, should, is)
    end

    def self.nil_array(elt)
      elt.nil? || (elt.is_a?(Array) && elt.length == 1 && elt[0].nil?)
    end

    def self.sub_elt(op, should, is)
      if should.is_a?(Hash) && is.is_a?(Hash)
        return self.hash_equiv?(op, should, is)
      elsif should.is_a?(Array) && is.is_a?(Array)
        return self.array_equiv?(op, should, is)
      else
        return !(should != is && !nil_array(should))
      end
    end

    def self.array_equiv?(op, should, is)
      n = should.length
      loop = lambda do|i|
        if i == n
          if op == :replace
            is.length == should.length
          else
            true
          end
        else
          should_elt = should[i]
          is_elt = is.find do |elt|
            sub_elt(op, should_elt, elt)
          end
          if is_elt.nil? && !nil_array(should_elt)
            should_elt.nil?
          else
            loop.call(i + 1)
          end
        end
      end
      loop.call(0)
    end

    def self.hash_equiv?(op, should, is)
      keys = should.keys
      n = keys.length
      loop = lambda do|i|
        if i == n
          if op == :replace
            is.keys.length == should.keys.length
          else
            true
          end
        else
          k = keys[i]
          is_v = is[k]
          should_v = should[k]
          if is_v.nil? && !nil_array(should_v)
            false
          else
            sub_elt(op, should_v, is_v) && loop.call(i + 1)
          end
        end
      end
      loop.call(0)
    end
  end # Yang
end # Cisco
