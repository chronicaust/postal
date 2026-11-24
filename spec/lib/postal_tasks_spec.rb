# frozen_string_literal: true

require "spec_helper"
require "rake"

describe "postal:fix_spam_check_descriptions" do
  around do |example|
    Rake.with_application do
      Rake::Task.define_task(:environment)
      Rake::Task.define_task("db:migrate")
      load File.expand_path("../../lib/tasks/postal.rake", __dir__)
      example.run
    end
  end

  it "migrates every server and reports failures without stopping the batch" do
    first = instance_double("Server", id: 1)
    second = instance_double("Server", id: 2)
    first_provisioner = instance_double("Postal::MessageDB::Provisioner")
    second_provisioner = instance_double("Postal::MessageDB::Provisioner")
    allow(first).to receive(:message_db).and_return(instance_double("Postal::MessageDB::Database", provisioner: first_provisioner))
    allow(second).to receive(:message_db).and_return(instance_double("Postal::MessageDB::Database", provisioner: second_provisioner))
    stub_const("Server", class_double("Server"))
    allow(Server).to receive(:find_each).and_yield(first).and_yield(second)
    allow(first_provisioner).to receive(:migrate).and_raise("migration failed")
    expect(second_provisioner).to receive(:migrate)

    expect do
      expect { Rake::Task["postal:fix_spam_check_descriptions"].invoke }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
    end.to output(/Message database migration failed for server 1: RuntimeError: migration failed.*Message database migrations failed for 1 server\(s\)/m).to_stderr
  end
end
