# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cisco_node_utils/version'

Gem::Specification.new do |spec|
  spec.name          = 'cisco_node_utils'
  spec.version       = CiscoNodeUtils::VERSION
  spec.authors       = ['Alex Hunsberger', 'Glenn Matthews',
                        'Chris Van Heuveln', 'Mike Wiebe', 'Jie Yang',
                        'Rob Gries']
  spec.email         = 'cisco_agent_gem@cisco.com'
  spec.summary       = 'Utilities for management of Cisco network nodes'
  spec.description   = <<-EOF
Utilities for management of Cisco network nodes.
Designed to work with Puppet and Chef.
Currently supports NX-OS nodes.
  EOF
  spec.license       = 'Apache-2.0'
  spec.homepage      = 'https://github.com/cisco/cisco-network-node-utils'

  spec.files         = `git ls-files -z`.split("\x0")
  # Files in bin/git are not executables as far as the Gem is concerned
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version     = '>= 2.0.0'
  spec.required_rubygems_version = '>= 2.1.0'

  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '= 0.35.1'
  spec.add_development_dependency 'simplecov', '~> 0.9'
  spec.add_runtime_dependency 'cisco_nxapi', '~> 1.0', '>= 1.0.1'
end
