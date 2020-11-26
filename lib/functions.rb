require "yaml"
require "json"
require "active_support/core_ext/hash"

class Stack
  attr_reader :name, :profile, :region, :states, :resources

  class << self
    attr_accessor :current

    def load_file(path)
      new(YAML.load_file(path))
    end
  end

  def initialize(attributes)
    @state_loaded = false

    %w(name profile region resources).each do |key|
      instance_variable_set("@#{key}", attributes[key])
    end

    @default_variables = attributes.fetch("variables")
    @states = load_states
  end

  def variables
    @variables ||= @default_variables.deep_merge(states.fetch(state_name))
  end

  def var(dot_splitted_name)
    if state_loaded?
      variables.dig(*dot_splitted_name.split("."))
    else
      @default_variables.dig(*dot_splitted_name.split("."))
    end
  end

  def state_name
    @state_name ||= begin
      unless File.exist?("stacks/#{name}.state")
        raise "Cannot found state for #{name}. Please run rake #{name}:state:*"
      end

      File.read("stacks/#{name}.state").strip
    end
  end

  private
  def state_loaded?
    @state_loaded
  end

  def load_states
    current = self.class.current
    self.class.current = self

    states = Dir["states/*.yml"].each_with_object({}) do |f, h|
      File.basename(f) =~ /(.*).yml/
      h[$1] = YAML.load_file(f)
    end

    @state_loaded = true
    states
  ensure
    self.class.current = current
  end
end

def add_yaml_tags
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

  YAML.add_domain_type("", "Join") do |_type, value|
    {"Fn::Join" => value}
  end

  YAML.add_domain_type("", "Ref") do |_type, value|
    {"Ref" => value}
  end

  YAML.add_domain_type("", "Var") do |_type, value|
    var = Stack.current.var(value)
    raise "Unknown variable `#{value}`" if var.nil?

    var
  end
end

add_yaml_tags

def build_template(stack)
  template = {
    "AWSTemplateFormatVersion" => "2010-09-09",
    "Resources" => {},
  }

  (stack.resources || Dir.glob("resources/**/*.yml")).sort.each do |yml|
    next unless (resources = YAML.load_file(yml))

    resources.each do |k, v|
      template["Resources"][k] = v
    end
  end

  # because to_yaml may includes aliasesl, convert json before dump
  JSON.parse(template.to_json).to_yaml
end
