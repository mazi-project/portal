Sequel.migration do
  up do
    add_column :applications, :type, String
    add_column :application_instances, :type, String
  end

  down do
    drop_column :applications, :type
    drop_column :application_instances, :type
  end
end
