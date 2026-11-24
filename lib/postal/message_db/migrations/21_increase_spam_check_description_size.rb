# frozen_string_literal: true

module Postal
  module MessageDB
    module Migrations
      class IncreaseSpamCheckDescriptionSize < Postal::MessageDB::Migration

        def up
          @database.query("ALTER TABLE `#{@database.database_name}`.`spam_checks` MODIFY `description` TEXT")
        end

      end
    end
  end
end
