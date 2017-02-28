Sequel.migration do
  up do
    create_table :sessions do
      primary_key :id
      Datetime :created_at
      String :ip
      String :uuid
    end
  end

  down do 
    drop_table(:sessions)
  end
end