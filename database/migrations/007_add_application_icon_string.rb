Sequel.migration do
  up do
    add_column :applications, :icon, String
    add_column :application_instances, :icon, String
  end

  down do
    drop_column :applications, :icon
    drop_column :application_instances, :icon
  end
end
