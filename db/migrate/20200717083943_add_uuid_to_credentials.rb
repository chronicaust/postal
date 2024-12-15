# frozen_string_literal: true

class AddUUIDToCredentials < ActiveRecord::Migration[7.0]

  def change
    add_column :credentials, :uuid, :string
    Credential.find_each do |c|
      c.update_column(:uuid, SecureRandom.uuid)
    end
  end

end
