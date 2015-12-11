# Inspired by:
# https://github.com/ruby-debug/ruby-debug-ide/blob/master/ext/mkrf_conf.rb

# This file needs to be named mkrf_conf.rb
# so that rubygems will recognize it as a ruby extension
# file and not think it is a C extension file

require 'rubygems/specification'
require 'rubygems/dependency'
require 'rubygems/dependency_installer'

# Load up the rubygems dependency installer to install the dependencies
# we need based on the platform we are running under.
installer = Gem::DependencyInstaller.new
deps = []
begin
  # Try to detect Cisco NX-OS and IOS XR environments
  os = nil
  if File.exist?('/etc/os-release')
    cisco_release_file = nil
    File.foreach('/etc/os-release') do |line|
      next unless line[/^CISCO_RELEASE_INFO=/]
      cisco_release_file = line[/^CISCO_RELEASE_INFO=(.*)$/, 1]
      break
    end
    unless cisco_release_file.nil?
      File.foreach(cisco_release_file) do |line|
        next unless line[/^ID=/]
        os = line[/^ID=(.*)$/, 1]
        break
      end
    end
  end
  puts "Detected client OS as '#{os}'" unless os.nil?

  # IOS XR doesn't need net_http_unix
  os == 'ios_xr' || deps << Gem::Dependency.new('net_http_unix',
                                                '~> 0.2', '>= 0.2.1')
  # NX-OS doesn't need gRPC
  os == 'nexus' || deps << Gem::Dependency.new('grpc', '~> 0.11')

  deps.each do |dep|
    installed = dep.matching_specs
    if installed.empty?
      puts "Installing #{dep}"
      installed = installer.install dep
      fail installer.errors[0] unless installer.errors.empty?
      fail "Did not install #{dep}" if installed.empty?
    else
      puts "Found installed gems matching #{dep}:"
      installed.each { |i| puts "  #{i.name} (#{i.version})" }
    end
  end
rescue StandardError => e
  puts e
  puts e.backtrace.join("\n  ")
  exit(1)
end

# Create a dummy Rakefile to report successful 'compilation'
f = File.open(File.join(File.dirname(__FILE__), 'Rakefile'), 'w')
f.write("task :default\n")
f.close
