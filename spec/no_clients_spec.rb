require_relative 'spec_helper.rb'

context 'when loading the core code explicitly' do
  it 'should not have any clients' do
    require 'cisco_node_utils/client/core'
    expect(Cisco::Client::CLIENTS).to eql []
  end
end

require 'rspec/core'

context 'when no client implementations are installed' do
  let(:main_self) { TOPLEVEL_BINDING.eval('self') }

  before(:example) do
    allow(main_self).to receive(:require).and_wrap_original do |orig, pkg|
      fail LoadError, pkg if pkg['client/nxapi']
      fail LoadError, pkg if pkg['client/grpc']
      orig.call(pkg)
    end
  end

  it 'should not have any clients' do
    require 'cisco_node_utils'
    expect(Cisco::Client::CLIENTS).to eql []
  end

  it 'should fail Client.create' do
    require 'cisco_node_utils'
    expect { Cisco::Client::Client.create('1.1.1.1', 'u', 'p') }.to \
      raise_error(RuntimeError, 'No client implementations available!')
  end
  # TODO
end
