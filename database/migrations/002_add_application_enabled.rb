Sequel.migration do
  up do
    add_column :applications, :enabled, TrueClass
  end

  down do 
    drop_column :applications, :enabled
  end
end