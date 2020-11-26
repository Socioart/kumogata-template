require "yaml"
require "io/console"
require "shellwords"
require_relative "lib/functions"

def ask_yesno(prompt)
  print prompt
  $stdin.gets.strip =~ /^y(es)?$/i
end

def kumogata2(stack, subcommand_and_args)
  sh "kumogata2 --profile #{stack.profile} --region #{stack.region} --capabilities CAPABILITY_IAM,CAPABILITY_NAMED_IAM #{subcommand_and_args}"
end

def aws(stack, *subcommand_and_args)
  sh "aws --profile #{stack.profile} --region #{stack.region} #{subcommand_and_args.shelljoin}"
end


STACKS = Dir["stacks/*.yml"].map {|f| Stack.load_file(f) }
DASHBOARDS = Dir["dashboards/*.yml"].map {|f| File.basename(f).gsub(/\.yml$/, "") }

STACKS.each do |stack|
  namespace stack.name do
    namespace "state" do
      stack.states.keys.each do |state|
        desc "Set #{stack.name} state state to #{state}"
        task state do
          mkdir_p "stacks"
          File.write("stacks/#{stack.name}.state", state)
        end
      end
    end

    task "state" do
      mkdir_p "stacks"
      puts File.read("stacks/#{stack.name}.state")
    end

    task "prepare" do
      Stack.current = stack
    end

    task "build" => "prepare" do
      template = build_template(stack)
      mkdir_p "tmp"
      File.write("tmp/#{stack.name}.yml", template)
    end

    desc "Show template for #{stack.name}"
    task "show" => "build" do
      sh "cat tmp/#{stack.name}.yml"
    end

    desc "Create stack #{stack.name}"
    task "create" => "build" do
      kumogata2 stack, "create tmp/#{stack.name}.yml #{stack.name}"
    end

    desc "Update stack #{stack.name}"
    task "update" => "build" do
      kumogata2 stack, "dry-run tmp/#{stack.name}.yml #{stack.name}"
      if ask_yesno("apply? (y/n): ")
        kumogata2 stack, "update tmp/#{stack.name}.yml #{stack.name}"
      end
    end

    namespace "dashboard" do
      DASHBOARDS.each do |dashboard|
        desc "Create / Update dashboard '#{dashboard}' for #{stack.name}"
        task dashboard => "prepare" do
          yaml = YAML.load_file("dashboards/#{dashboard}.yml")
          yaml = replace_var(yaml, stack)
          aws stack, "cloudwatch", "put-dashboard", "--dashboard-name", yaml["name"], "--dashboard-body", yaml["body"].to_json
        end
      end
    end

    desc "Create / Update all dashboards for #{stack.name}"
    task "dashboard" => DASHBOARDS.map {|d| "dashboard:#{d}"}
  end
end
