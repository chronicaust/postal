# frozen_string_literal: true

namespace :postal do
  desc "Run all migrations on message databases"
  task migrate_message_databases: :environment do
    Server.all.each do |server|
      puts "Running migrations for #{server.organization.permalink}/#{server.permalink} (ID: #{server.id})"
      server.message_db.provisioner.migrate
    end
  end

  desc "Widen spam check descriptions by running pending message database migrations on all servers"
  task fix_spam_check_descriptions: :environment do
    failures = 0
    Server.find_each do |server|
      puts "Running message database migrations for server #{server.id}"
      server.message_db.provisioner.migrate
    rescue StandardError => e
      failures += 1
      warn "Message database migration failed for server #{server.id}: #{e.class}: #{e.message}"
    end

    abort "Message database migrations failed for #{failures} server(s)" if failures.positive?
  end

  desc "Generate configuration documentation"
  task generate_config_docs: :environment do
    require "konfig/exporters/env_vars_as_markdown"

    FileUtils.mkdir_p("doc/config")
    output = Konfig::Exporters::EnvVarsAsMarkdown.new(Postal::ConfigSchema).export
    File.write("doc/config/environment-variables.md", output)

    output = Postal::YamlConfigExporter.new(Postal::ConfigSchema).export
    File.write("doc/config/yaml.yml", output)
  end

  desc "Generate Helm Environment Variables"
  task generate_helm_env_vars: :environment do
    puts Postal::HelmConfigExporter.new(Postal::ConfigSchema).export
  end

  desc "Update the database"
  task update: :environment do
    mysql = ActiveRecord::Base.connection
    if mysql.table_exists?("schema_migrations") &&
       mysql.select_all("select * from schema_migrations").any?
      puts "Database schema is already loaded. Running migrations with db:migrate"
      Rake::Task["db:migrate"].invoke
    else
      puts "No schema migrations exist. Loading schema with db:schema:load"
      Rake::Task["db:schema:load"].invoke
    end
  end
end

Rake::Task["db:migrate"].enhance do
  Rake::Task["postal:migrate_message_databases"].invoke
end
