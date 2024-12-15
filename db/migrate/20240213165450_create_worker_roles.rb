# frozen_string_literal: true

class CreateWorkerRoles < ActiveRecord::Migration[7.0]

  def change
    create_table :worker_roles do |t|
      t.string :role
      t.string :worker
      t.datetime :acquired_at
      t.index :role, unique: true
    end
  end

end
