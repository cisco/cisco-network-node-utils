#!/usr/bin/env ruby
#
# January 2016, Glenn F. Matthews
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

require_relative 'client_errors'
require_relative '../constants'
require_relative '../logger'

include Cisco::Logger

# Utility methods for clients of various RPC formats
class Cisco::Client
  # Helper function that subclasses may use with get(data_format: :cli)
  # Method for working with hierarchical show command output such as
  # "show running-config". Searches the given multi-line string
  # for all matches to the given value query. If context is provided,
  # the matches will be filtered to only those that are located "under"
  # the given context sequence (as determined by indentation).
  #
  # @param cli_output [String] The body of text to search
  # @param context [*Regex] zero or more regular expressions defining
  #                the parent configs to filter by.
  # @param value [Regex] The regular expression to match
  # @return [[String], nil] array of matching (sub)strings, else nil.
  #
  # @example Find all OSPF router names in the running-config
  #   ospf_names = filter_cli(cli_output: running_cfg,
  #                           value:      /^router ospf (\d+)/)
  #
  # @example Find all address-family types under the given BGP router
  #   bgp_afs = filter_cli(cli_output: show_run_bgp,
  #                        context:    [/^router bgp #{ASN}/],
  #                        value:      /^address-family (.*)/)
  def self.filter_cli(cli_output: nil,
                      context:    nil,
                      value:      nil)
    return cli_output if cli_output.nil?
    context ||= []
    context.each { |filter| cli_output = find_subconfig(cli_output, filter) }
    return cli_output if cli_output.nil? || cli_output.empty? || value.nil?
    match = cli_output.scan(value)
    return nil if match.empty?
    # find matches and return as array of String if it only does one match.
    # Otherwise return array of array.
    match.flatten! if match[0].is_a?(Array) && match[0].length == 1
    match
  end

  # Returns the subsection associated with the given
  # line of config
  # @param [String] the body of text to search
  # @param [Regex] the regex key of the config for which
  # to retrieve the subsection
  # @return [String, nil] the subsection of body, de-indented
  # appropriately, or nil if no such subsection exists.
  def self.find_subconfig(body, regex_query)
    return nil if body.nil? || regex_query.nil?

    rows = body.split("\n")
    match_row_index = rows.index { |row| regex_query =~ row }
    return nil if match_row_index.nil?

    cur = match_row_index + 1
    subconfig = []

    until (/\A\s+.*/ =~ rows[cur]).nil? || cur == rows.length
      subconfig << rows[cur]
      cur += 1
    end
    return nil if subconfig.empty?
    # Strip an appropriate minimal amount of leading whitespace from
    # all lines in the subconfig
    min_leading = subconfig.map { |line| line[/\A */].size }.min
    subconfig = subconfig.map { |line| line[min_leading..-1] }
    subconfig.join("\n")
  end

  # Helper method for get(data_format: :nxapi_structured).
  #
  # @param data [Array, Hash] structured output from node
  # @param keys [Array] lookup sequence
  def self.filter_data(data: nil,
                       keys: nil)
    return nil if data.nil?
    keys ||= []
    keys.each do |filter|
      # if filter is a Hash and data is an array, check each
      # array index (which should return another hash) to see if
      # it contains the matching key/value pairs specified in token,
      # and return the first match (or nil)
      if filter.kind_of?(Hash)
        fail "Expected Array, got #{data.class}" unless data.is_a? Array
        data = data.select { |x| filter.all? { |k, v| x[k] == v } }
        fail "Multiple matches found for #{filter}" if data.length > 1
        fail "No match found for #{filter}" if data.length == 0
        data = data[0]
      else # data is array or hash
        filter = filter.to_i if data.is_a? Array
        fail "No key \"#{filter}\" in #{data}" if data[filter].nil?
        data = data[filter]
      end
    end
    data
  end
end
