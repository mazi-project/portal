Sequel.migration do
  up do
    add_column :application_instances, :splash_screen, TrueClass
  end

  down do
    drop_column :applications, :splash_screen
  end
end