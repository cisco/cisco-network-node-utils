require_relative 'spec_helper.rb'
require 'shared_examples_for_clients'
require 'cisco_node_utils/client/grpc'

describe Cisco::Client::GRPC do
  it_behaves_like 'all clients'

  describe '.validate_args' do
    it 'rejects nil username' do
      kwargs = { host: '1.1.1.1', username: nil, password: 'bye' }
      expect { described_class.validate_args(**kwargs) }.to \
        raise_error(TypeError,
                    'gRPC client creation failure: username must be specified')
    end

    it 'rejects nil password' do
      kwargs = { host: '1.1.1.1', username: 'hi', password: nil }
      expect { described_class.validate_args(**kwargs) }.to \
        raise_error(TypeError,
                    'gRPC client creation failure: password must be specified')
    end
  end
end
