Sequel.migration do
  up do
    create_table :applications do
      primary_key :id
      String  :name
      String  :description
      String  :url
      Integer :click_counter
    end
  end

  down do 
    drop_table(:applications)
  end
end