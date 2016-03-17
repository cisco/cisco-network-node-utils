shared_examples_for 'all clients' do
  describe '.validate_args' do
    %i(host username password).each do |sym|
      it "rejects non-String #{sym}" do
        expect { described_class.validate_args(sym => 12) }.to \
          raise_error(TypeError)
      end
      it "rejects empty #{sym}" do
        expect { described_class.validate_args(sym => '') }.to \
          raise_error(ArgumentError)
      end
    end
  end
end
