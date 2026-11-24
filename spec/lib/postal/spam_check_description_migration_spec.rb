# frozen_string_literal: true

require "rails_helper"
require "postal/message_db/migrations/01_create_migrations"
require "postal/message_db/migrations/10_create_spam_checks"

describe "Spam check description migration" do
  let(:database) { Postal::MessageDB::Database.new(1, 1, database_name: "postal-test-spam-checks-#{SecureRandom.hex(6)}") }

  before do
    database.provisioner.create
    Postal::MessageDB::Migrations::CreateMigrations.new(database).up
    Postal::MessageDB::Migrations::CreateSpamChecks.new(database).up
    database.insert(:migrations, version: 20)
  end

  after do
    database.provisioner.drop
  end

  it "preserves existing descriptions and allows a longer description in a multi-row insert" do
    database.insert(:spam_checks, description: "Existing result")

    database.provisioner.migrate(silent: true)

    long_description = "Long spam check result " * 20
    database.insert_multi(:spam_checks, [:description], [["Short result"], [long_description]])
    descriptions = database.select(:spam_checks, order: :id, fields: [:description]).map { |row| row.fetch("description") }
    expect(descriptions).to eq(["Existing result", "Short result", long_description])
  end
end
