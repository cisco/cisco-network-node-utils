require_relative 'spec_helper.rb'
require 'cisco_node_utils/environment'
require 'cisco_node_utils/client'

class << Cisco::Environment
  attr_writer :environments
end

describe Cisco::Environment do
  after(:each) do
    # Revert to default environment data
    Cisco::Environment.environments = {}
  end

  describe '.data_from_file' do
    it 'handles File.expand_path errors' do
      expect(File).to receive(:expand_path).and_raise(ArgumentError)
      expect(Cisco::Environment.data_from_file('~/foo/bar.yaml')).to be_empty
    end

    it 'handles nonexistent files' do
      expect(File).to receive(:file?).and_return(false)
      expect(Cisco::Environment.data_from_file('/foo/bar.yaml')).to be_empty
    end

    it 'handles unreadable files' do
      expect(File).to receive(:file?).and_return(true)
      expect(File).to receive(:readable?).and_return(false)
      expect(Cisco::Environment.data_from_file('/foo/bar.yaml')).to be_empty
    end

    it 'handles YAML errors' do
      expect(File).to receive(:file?).and_return(true)
      expect(File).to receive(:readable?).and_return(true)
      error = Psych::SyntaxError.new('/foo/bar.yaml', 1, 1, 0, 'foo', 'bar')
      expect(YAML).to receive(:load_file).and_raise(error)
      # Catch the error log message Environment will generate:
      expect(Cisco::Logger).to receive(:error).once
      expect(Cisco::Environment.data_from_file('/foo/bar.yaml')).to eq({})
    end
  end

  describe '.merge_config' do
    it 'merges valid content' do
      base = { 'hello' => {
        host:     '2.2.2.2',
        port:     57_799,
        username: nil,
        password: nil,
        cookie:   nil,
      } }
      expect(Cisco::Environment).to receive(:data_from_file).and_return(
        'hello' => { host: '1.1.1.1' }, 'goodbye' => { password: 'foo' })
      expect(Cisco::Environment.merge_config('/foo/bar.yaml', base)).to eq(
        'hello'   => {
          host:     '1.1.1.1',
          port:     57_799,
          username: nil,
          password: nil,
          cookie:   nil,
        },
        'goodbye' => {
          host:     nil,
          port:     nil,
          username: nil,
          password: 'foo',
          cookie:   nil,
        },
      )
    end
  end

  describe '.environments' do
    before(:each) do
      allow(Cisco::Environment).to receive(:data_from_file).and_return({})
    end

    it 'is empty by default' do
      expect(Cisco::Environment.environments).to be_empty
    end

    global_config = {
      'default' => {
        host:   '127.0.0.1',
        port:   57_400,
        cookie: nil,
      },
      'global'  => {
        username: 'global',
        password: 'global',
        cookie:   nil,
      },
    }

    user_config = {
      'default' => {
        port:     57_799,
        username: 'user',
        cookie:   nil,
      },
      'user'    => {
        username: 'user',
        password: 'user',
        cookie:   nil,
      },
    }

    it 'loads data from global config if present' do
      expect(Cisco::Environment).to receive(:data_from_file).with(
        '/etc/cisco_node_utils.yaml').and_return(global_config)
      env = Cisco::Environment.environments
      env.each do |key, hash|
        # The env hash should be fully populated with keys
        # Any keys unspecified in the data should be nil
        %I(host port username password).each do |hash_key|
          expect(hash.fetch(hash_key)).to \
            eq(global_config[key].fetch(hash_key, nil))
        end
      end
    end

    it 'loads data from user config if present' do
      expect(Cisco::Environment).to receive(:data_from_file).with(
        '~/cisco_node_utils.yaml').and_return(user_config)
      env = Cisco::Environment.environments
      env.each do |key, hash|
        # The env hash should be fully populated with keys
        # Any keys unspecified in the data should be nil
        %I(host port username password).each do |hash_key|
          expect(hash.fetch(hash_key)).to \
            eq(user_config[key].fetch(hash_key, nil))
        end
      end
    end

    it 'uses both files if present but user data takes precedence' do
      expect(Cisco::Environment).to receive(:data_from_file).with(
        '/etc/cisco_node_utils.yaml').and_return(global_config)
      expect(Cisco::Environment).to receive(:data_from_file).with(
        '~/cisco_node_utils.yaml').and_return(user_config)
      expect(Cisco::Environment.environments).to eq(
        'default' => {
          host:     '127.0.0.1', # global config
          port:     57_799, # user overrides global
          username: 'user', # user config
          password: nil, # auto-populated with nil
          cookie:   nil,
        },
        'global'  => { # global config
          host:     nil,
          port:     nil,
          username: 'global',
          password: 'global',
          cookie:   nil,
        },
        'user'    => { # user config
          host:     nil,
          port:     nil,
          username: 'user',
          password: 'user',
          cookie:   nil,
        },
      )
    end
  end

  context '.environment' do
    context 'with no config files available' do
      before(:each) do
        allow(Cisco::Environment).to receive(:data_from_file).and_return({})
      end

      it 'returns DEFAULT_ENVIRONMENT when called with no args' do
        expect(Cisco::Environment.environment).to \
          eq(Cisco::Environment::DEFAULT_ENVIRONMENT)
      end
      it 'returns DEFAULT_ENVIRONMENT when requested by name as "default"' do
        expect(Cisco::Environment.environment('default')).to \
          eq(Cisco::Environment::DEFAULT_ENVIRONMENT)
      end
    end

    context 'with examples in docs/cisco_node_utils.yaml.example' do
      before(:each) do
        allow(File).to receive(:file?).and_return(true)
        allow(File).to receive(:readable?).and_return(true)
        allow(YAML).to receive(:load_file).and_wrap_original do |orig|
          orig.call(File.expand_path('docs/cisco_node_utils.yaml.example'))
        end
      end

      context 'the "nxapi_local" example' do
        expected = {
          host:     nil,
          port:     nil,
          username: nil,
          password: nil,
          cookie:   nil,
        }
        it 'can be loaded explicitly by name' do
          expect(Cisco::Environment.environment('nxapi_local')).to eq(expected)
        end
        it 'can be specified as the default then loaded implicitly' do
          Cisco::Environment.default_environment_name = 'nxapi_local'
          expect(Cisco::Environment.environment).to eq(expected)
        end
        it 'is valid configuration for the NXAPI client' do
          hash = Cisco::Environment.environment('nxapi_local')
          Cisco::Client::NXAPI.validate_args(hash)
        end
      end

      context 'the "nxapi_remote" example' do
        expected = {
          host:     '192.168.1.100',
          port:     nil,
          username: 'devops',
          password: 'devops',
          cookie:   nil,
        }
        it 'can be loaded explicitly by name' do
          expect(Cisco::Environment.environment('nxapi_remote')).to eq(expected)
        end
        it 'can be specified as the default then loaded implicitly' do
          Cisco::Environment.default_environment_name = 'nxapi_remote'
          expect(Cisco::Environment.environment).to eq(expected)
        end
        it 'is valid configuration for the NXAPI client' do
          hash = Cisco::Environment.environment('nxapi_remote')
          Cisco::Client::NXAPI.validate_args(hash)
        end
      end

      context 'the "grpc_local" example' do
        expected = {
          host:     nil,
          port:     57_999,
          username: 'admin',
          password: 'admin',
          cookie:   nil,
        }
        it 'can be loaded explicitly by name' do
          expect(Cisco::Environment.environment('grpc_local')).to eq(expected)
        end
        it 'can be specified as default then loaded implicitly' do
          Cisco::Environment.default_environment_name = 'grpc_local'
          expect(Cisco::Environment.environment).to eq(expected)
        end
        it 'is valid configuration for the gRPC client' do
          hash = Cisco::Environment.environment('grpc_local')
          Cisco::Client::GRPC.validate_args(hash)
        end
      end

      context 'the "grpc_remote" example' do
        expected = {
          host:     '192.168.1.100',
          port:     nil,
          username: 'admin',
          password: 'admin',
          cookie:   nil,
        }
        it 'can be loaded explicitly by name' do
          expect(Cisco::Environment.environment('grpc_remote')).to eq(expected)
        end
        it 'can be specified as default then loaded implicitly' do
          Cisco::Environment.default_environment_name = 'grpc_remote'
          expect(Cisco::Environment.environment).to eq(expected)
        end
        it 'is valid configuration for the gRPC client' do
          hash = Cisco::Environment.environment('grpc_remote')
          Cisco::Client::GRPC.validate_args(hash)
        end
      end
    end
  end
end
