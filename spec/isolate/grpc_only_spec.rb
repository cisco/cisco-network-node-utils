require_relative '../spec_helper.rb'

context 'when only gRPC client is installed' do
  let(:main_self) { TOPLEVEL_BINDING.eval('self') }
  before(:example) do
    allow(main_self).to receive(:require).and_wrap_original do |orig, pkg|
      fail LoadError, pkg if pkg['cisco_node_utils/client/nxapi']
      orig.call(pkg)
    end
  end

  it 'should have gRPC client' do
    require 'cisco_node_utils'
    expect(Cisco::Client.clients).to eql [Cisco::Client::GRPC]
  end
end
