require_relative 'spec_helper.rb'
require 'cisco_node_utils/environment'
require 'cisco_node_utils/client'

describe Cisco::Environment do
  context '#merge_config' do
    it 'handles File.expand_path errors' do
      expect(File).to receive(:expand_path).and_raise(ArgumentError)
      expect(Cisco::Environment.merge_config('~/foo/bar.yaml', {})).to eq({})
    end

    it 'handles nonexistent files' do
      expect(File).to receive(:file?).and_return(false)
      expect(Cisco::Environment.merge_config('/foo/bar.yaml', {})).to eq({})
    end

    it 'handles unreadable files' do
      expect(File).to receive(:file?).and_return(true)
      expect(File).to receive(:readable?).and_return(false)
      expect(Cisco::Environment.merge_config('/foo/bar.yaml', {})).to eq({})
    end

    it 'merges valid content' do
      base = { 'hello' => {
        host:     '2.2.2.2',
        port:     57_799,
        username: nil,
        password: nil,
      } }
      expect(File).to receive(:file?).and_return(true)
      expect(File).to receive(:readable?).and_return(true)
      expect(YAML).to receive(:load_file).and_return(
        'hello' => { host: '1.1.1.1' }, 'goodbye' => { password: 'foo' })
      expect(Cisco::Environment.merge_config('/foo/bar.yaml', base)).to eq(
        'hello'   => {
          host:     '1.1.1.1',
          port:     57_799,
          username: nil,
          password: nil,
        },
        'goodbye' => {
          host:     nil,
          port:     nil,
          username: nil,
          password: 'foo',
        },
      )
    end
  end

  context 'default values' do
    before(:example) do
      allow(File).to receive(:file?).and_return(false)
    end
    expected = {
      host:     nil,
      port:     nil,
      username: nil,
      password: nil,
    }
    it 'is loaded by default' do
      expect(Cisco::Environment.environment).to eq(expected)
    end
    it 'can be loaded explicitly by name' do
      expect(Cisco::Environment.environment('default')).to eq(expected)
    end
  end

  context 'examples in docs/cisco_node_utils.yaml.example' do
    before(:example) do
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
