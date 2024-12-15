# frozen_string_literal: true

class RemoveTypeFromIPPools < ActiveRecord::Migration[7.0]

  def change
    remove_column :ip_pools, :type, :string
  end

end
