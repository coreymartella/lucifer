require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'rubygems'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/debug.log')
ActiveRecord::Base.configurations = {'test' => config[ENV['DB'] || 'sqlite3']}
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])

load(File.dirname(__FILE__) + '/schema.rb')

require File.join(File.dirname(__FILE__), 'person')

class LuciferTest < Test::Unit::TestCase

  def test_encrypt_proper_columns
    assert_equal ['ssn_encrypted'], Person.encrypted_columns
  end
  
  def test_track_decrypted_columns
    assert_equal ['ssn'], Person.decrypted_columns
  end
  
  def test_setup_virtual_attributes
    assert Person.new.respond_to?(:ssn)
    assert Person.new.respond_to?('ssn=')
  end
  
  def test_encrypt_column_before_save
    person = Person.new :name=>'Alice', :ssn=>'000-00-0000'
    assert_nil person.ssn_encrypted
    person.save
    assert person.ssn_encrypted
    assert_not_equal '000-00-0000', person.ssn_encrypted
  end
  
  def test_decrypt_columns_on_load
    id = Person.create(:name=>'Bob', :ssn=>'999-99-9999').id
    person = Person.find id
    assert_equal '999-99-9999', person.ssn
  end
  
  def test_encrypt_null_column_before_save
    person = Person.new :name=>'Alice', :ssn=>nil
    assert_nil person.ssn_encrypted
    person.save
    assert_nil person.ssn_encrypted
  end
  
  def test_decrypt_null_columns_on_load
    id = Person.create(:name=>'Bob', :ssn=>nil).id
    person = Person.find id
    assert_nil person.ssn
  end
  
end