# frozen_string_literal: true

class AddPrivacyModeToServers < ActiveRecord::Migration[7.0]

  def change
    add_column :servers, :privacy_mode, :boolean, default: false
  end

end
