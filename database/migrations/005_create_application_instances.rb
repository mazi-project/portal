Sequel.migration do
  up do
    create_table :application_instances do
      primary_key :id
      foreign_key :application_id, :applications
      String      :name
      String      :description
      String      :url
      Integer     :click_counter
      TrueClass   :enabled
    end
  end

  down do 
    drop_table(:application_instances)
  end
end