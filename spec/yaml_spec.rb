require_relative 'spec_helper.rb'
require 'kwalify'
require 'yaml'

files = Dir.glob(__dir__ + '/../lib/cisco_node_utils/cmd_ref/*.yaml')

def print_errors(errors)
  str = "Schema validation errors:\n"
  error_str_list = errors.map do |e|
    "line #{e.linenum}, column #{e.column}: [#{e.path}] #{e.message}"
  end
  str + error_str_list.join("\n")
end

# Use the MetaValidator to make sure the schema itself is sane
metavalidator = Kwalify::MetaValidator.instance

schema_file = File.join(__dir__, 'schema.yaml')

metaparser = Kwalify::Yaml::Parser.new(metavalidator)
context 'schema.yaml' do
  it 'should have no schema metavalidation errors' do
    metaparser.parse_file(schema_file)
    errors = metaparser.errors()
    expect(errors).to be_empty, -> { print_errors(errors) }
  end
end

# Then use the Validator to make sure our files comply with the schema
schema = Kwalify::Yaml.load_file(schema_file)
validator = Kwalify::Validator.new(schema)
parser = Kwalify::Yaml::Parser.new(validator)

files.each do |file|
  context file.split('/')[-1] do
    it 'should have no schema validation errors' do
      parser.parse_file(file)
      errors = parser.errors()
      expect(errors).to be_empty, -> { print_errors(errors) }
    end
  end
end
