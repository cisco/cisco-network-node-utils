require_relative '../spec_helper.rb'

context 'when both clients are installed' do
  it 'should have both clients' do
    require 'cisco_node_utils'
    expect(Cisco::Client.clients).to eql [Cisco::Client::NXAPI,
                                          Cisco::Client::GRPC]
  end
end
