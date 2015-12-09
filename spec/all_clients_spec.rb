require_relative 'spec_helper.rb'

context 'when both clients are installed' do
  it 'should have both clients' do
    require 'cisco_node_utils'
    expect(Cisco::Client::CLIENTS).to eql [Cisco::Client::NXAPI::Client,
                                           Cisco::Client::GRPC::Client]
  end
end
