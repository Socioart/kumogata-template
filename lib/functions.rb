require "yaml"
require "json"

def add_yaml_tags(variables)
  # Register tags to parse abbreviated function call like `!Ref: Foo`
  # See: https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html
  %w(And Base64 Cidr Equals FindInMap GetAZs If ImportValue Join Not Or Select Split Sub Transform).each do |tag|
    YAML.add_domain_type("", tag) do |_type, value|
      {"Fn::" + tag => value}
    end
  end

  YAML.add_domain_type("", "GetAtt") do |_type, value|
    {"Fn::GetAtt" => value.split(".")}
  end

  YAML.add_domain_type("", "Ref") do |_type, value|
    {"Ref" => value}
  end

  YAML.add_domain_type("", "Var") do |_type, value|
    var = variables.dig(*value.split("."))
    raise "Unknown variable `#{value}`" if var.nil?

    var
  end
end

def build_template
  template = {
    "AWSTemplateFormatVersion" => "2010-09-09",
    "Resources" => {},
  }

  Dir.glob("resources/**/*.yml").sort.each do |yml|
    YAML.load_file(yml).each do |k, v|
      template["Resources"][k] = v
    end
  end

  # because to_yaml may includes aliasesl, convert json before dump
  JSON.parse(template.to_json).to_yaml
end
