ActiveRecord::Schema.define(:version=>0) do
  create_table :people, :force=>true do |t|
    t.string :name
    t.string :ssn_encrypted
    t.binary :picture
  end
end
