require_relative 'spec_helper.rb'

# Whitespace in ruby files is managed by Rubocop
context 'non-ruby files' do
  failures = `git grep -n -I ' $' | grep -v .rb`
  it 'should have no trailing whitespace' do
    expect(failures).to be_empty, -> { failures }
  end
end
