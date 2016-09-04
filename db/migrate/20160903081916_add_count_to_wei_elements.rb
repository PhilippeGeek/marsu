class AddCountToWeiElements < ActiveRecord::Migration
  def change
    add_column :wei_buses, :wei_registrations_count, :integer, default: 0
    add_column :wei_bungalows, :wei_registrations_count, :integer, default: 0
  end
end
