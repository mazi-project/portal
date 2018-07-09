Sequel.migration do
  up do
    add_column :application_instances, :order, Integer
  end

  down do
    drop_column :application_instances, :order
  end
end
