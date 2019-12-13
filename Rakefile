require "yaml"
require "io/console"
require_relative "lib/functions"

def ask_yesno(prompt)
  print prompt
  $stdin.gets.strip =~ /^y(es)?$/i
end

def kumogata2(stack, subcommand_and_args)
  sh "kumogata2 --profile #{stack["profile"]} --region #{stack["region"]} --capabilities CAPABILITY_IAM #{subcommand_and_args}"
end

STACKS = Dir["stacks/*.yml"].map {|f| YAML.load_file(f) }
STACKS.each do |stack|
  namespace stack["name"] do
    namespace "state" do
      stack["states"].keys.each do |state|
        desc "Set #{stack["name"]} state state to #{state}"
        task state do
          mkdir_p "states"
          File.write("states/#{stack["name"]}", state)
        end
      end
    end

    task "prepare" do
      add_yaml_tags(stack)
    end

    task "build" => "prepare" do
      template = build_template
      mkdir_p "tmp"
      File.write("tmp/#{stack["name"]}.yml", template)
    end

    desc "Show template for #{stack["name"]}"
    task "show" => "build" do
      sh "cat tmp/#{stack["name"]}.yml"
    end

    desc "Create stack #{stack["name"]}"
    task "create" => "build" do
      kumogata2 stack, "create tmp/#{stack["name"]}.yml #{stack["name"]}"
    end

    desc "Update stack #{stack["name"]}"
    task "update" => "build" do
      kumogata2 stack, "dry-run tmp/#{stack["name"]}.yml #{stack["name"]}"
      if ask_yesno("apply? (y/n): ")
        kumogata2 stack, "update tmp/#{stack["name"]}.yml #{stack["name"]}"
      end
    end
  end
end
