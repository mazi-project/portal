Sequel.migration do
  up do
    add_column :applications, :color, String
    add_column :application_instances, :color, String
  end

  down do
    drop_column :applications, :color
    drop_column :application_instances, :color
  end
end
