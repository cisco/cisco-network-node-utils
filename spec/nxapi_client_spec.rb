require_relative 'spec_helper.rb'
require 'shared_examples_for_clients'
require 'cisco_node_utils/client/nxapi'

describe Cisco::Client::NXAPI do
  it_behaves_like 'all clients'

  describe '.validate_args' do
    it 'accepts nil host, username, and password together' do
      described_class.validate_args
    end

    it 'rejects the combination of nil host with non-nil username' do
      kwargs = { host: nil, username: 'hi', password: nil }
      expect { described_class.validate_args(**kwargs) }.to \
        raise_error(ArgumentError)
    end

    it 'rejects the combination of nil host with non-nil password' do
      kwargs = { host: nil, username: nil, password: 'bye' }
      expect { described_class.validate_args(**kwargs) }.to \
        raise_error(ArgumentError)
    end

    it 'accepts a host with username and password' do
      kwargs = { host: '1.1.1.1', username: 'hi', password: 'bye' }
      described_class.validate_args(**kwargs)
    end

    it 'rejects a host with nil username' do
      kwargs = { host: '1.1.1.1', username: nil, password: 'bye' }
      expect { described_class.validate_args(**kwargs) }.to \
        raise_error(TypeError, 'username is required')
    end

    it 'rejects a host with nil password' do
      kwargs = { host: '1.1.1.1', username: 'hi', password: nil }
      expect { described_class.validate_args(**kwargs) }.to \
        raise_error(TypeError, 'password is required')
    end
  end
end
