require_relative 'spec_helper.rb'

context 'non-ruby files' do
  # Whitespace in ruby files is managed by Rubocop.
  # Ignore ems.proto as it's a generated file.
  failures = `git grep -n -I '\s$' | grep -v .rb | grep -v ems.proto`
  it 'should have no trailing whitespace' do
    expect(failures).to be_empty, -> { failures }
  end
end
