require_relative '../spec_helper.rb'

context 'when only NXAPI client is installed' do
  let(:main_self) { TOPLEVEL_BINDING.eval('self') }
  before(:example) do
    allow(main_self).to receive(:require).and_wrap_original do |orig, pkg|
      fail LoadError, pkg if pkg['cisco_node_utils/client/grpc']
      orig.call(pkg)
    end
  end

  it 'should have NXAPI client' do
    require 'cisco_node_utils/client'
    expect(Cisco::Client.clients).to eql [Cisco::Client::NXAPI]
  end
end
