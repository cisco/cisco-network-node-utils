#!/usr/bin/env ruby
#
# October 2015, Glenn F. Matthews
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
#
# This is a helper script for developers.
# If you're doing refactoring work to reduce the code complexity metrics,
# you can run this script to report the worst offenders for each metric
# and whether you've managed to improve any metrics compared to the baseline.

require 'pathname'
require 'yaml'

base = Pathname.new(File.expand_path('../..', __FILE__))

['lib/', 'tests/'].each do |subdir|
  # Read in the base config file:
  base_config = {}
  File.open(base + subdir + '.rubocop.yml', 'r') do |f|
    base_config = YAML.parse(f).transform
  end

  # Create a fake config file that's identical to baseline except for the
  # metric Max limits:

  new_config = {}
  base_config.each do |cop, options|
    next unless options.is_a?(Hash)
    new_config[cop] = {}
    options.each do |option, value|
      new_config[cop][option] = value unless option == 'Max'
    end
  end

  tempfile = base + '.rubocop_temp.yml'

  File.open(tempfile, 'w') do |f|
    f.write new_config.to_yaml
  end

  output = `rubocop -c #{tempfile} --only Metrics -f emacs \
-D #{subdir} 2>/dev/null`
  `rm -f #{tempfile}`

  results = {}
  output.split("\n").each do |line|
    # emacs output format:
    # foo/bar.rb:92:81: C: Metrics/LineLength: Line is too long. [81/80]
    file, row, col, _err, cop, msg = line.split(':')
    file = Pathname.new(file).relative_path_from(base).to_s
    cop.strip!
    value = msg[/\[([0-9.]+)/, 1].to_f.ceil
    results[cop] ||= {}
    results[cop][value] ||= []
    results[cop][value] << {
      file: file,
      row:  row.to_i,
      col:  col.to_i,
    }
  end

  # Print each failing cop in alphabetical order...
  results.keys.sort.each do |cop|
    puts "\n#{cop}"
    offenses = results[cop]
    # List the two highest failing values...
    offenses.keys.sort.reverse[0..1].each do |value|
      puts "  #{value}:"
      offenses[value].each do |offender|
        # and list the file and line where each failure was seen
        puts "    #{offender[:file]}:#{offender[:row]}"
      end
    end
  end

  puts "\n"

  base_config.keys.sort.each do |cop|
    next unless cop =~ /Metrics/
    base_val = base_config[cop]['Max']
    base_val ||= 0
    actual_val = results[cop].keys.sort.last if results[cop]
    actual_val ||= 0
    if base_val == actual_val
      if base_val == 0
        puts "#{cop}: still passing in full"
      else
        puts "#{cop}: value unchanged (#{base_val})"
      end
    elsif base_val > actual_val
      puts "#{cop}: value improved! (#{base_val} -> #{actual_val})"
    else
      puts "#{cop}: value WORSENED (#{base_val} -> #{actual_val})"
    end
  end
end
