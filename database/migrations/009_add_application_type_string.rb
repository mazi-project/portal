Sequel.migration do
  up do
    add_column :applications, :type, String
  end

  down do
    drop_column :applications, :type
  end
end
