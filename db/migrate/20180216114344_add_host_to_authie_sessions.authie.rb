# frozen_string_literal: true

# This migration comes from authie (originally 20180215152200)
class AddHostToAuthieSessions < ActiveRecord::Migration[7.0]

  def change
    add_column :authie_sessions, :host, :string
  end

end
