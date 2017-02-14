Sequel.migration do
  up do
    create_table :notifications do
      primary_key :id
      String  :title
      String  :body
      TrueClass :enabled
    end
  end

  down do 
    drop_table(:notifications)
  end
end