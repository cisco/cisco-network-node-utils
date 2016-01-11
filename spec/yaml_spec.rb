require_relative 'spec_helper.rb'
require 'kwalify'
require 'yaml'

files = Dir.glob(__dir__ + '/../lib/cisco_node_utils/cmd_ref/*.yaml')

# TODO: use Kwalify::MetaValidator to validate the schema itself

schema = Kwalify::Yaml.load_file(File.join(__dir__, 'schema.yaml'))
validator = Kwalify::Validator.new(schema)
parser = Kwalify::Yaml::Parser.new(validator)

def print_errors(errors)
  str = "Schema validation errors:\n"
  error_str_list = errors.map do |e|
    "line #{e.linenum}, column #{e.column}: [#{e.path}] #{e.message}"
  end
  str + error_str_list.join("\n")
end

files.each do |file|
  context file.split('/')[-1] do
    it 'should have no schema validation errors' do
      parser.parse_file(file)
      errors = parser.errors()
      expect(errors).to be_empty, -> { print_errors(errors) }
    end
  end
end
