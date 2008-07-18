require 'base64'
module Lucifer
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def encrypt_attributes(options = {})
      return if self.included_modules.include? Lucifer::InstanceMethods
      __send__ :include, Lucifer::InstanceMethods
      
      cattr_accessor :encrypted_columns, :decrypted_columns, :key, :suffix, :key_file
      
      self.suffix   = options[:suffix]   || '_encrypted'
      self.key_file = options[:key_file] || 'key.yml'
      
      self.encrypted_columns = columns.select{|col| col.type == :string && col.name.ends_with?(suffix)}.collect(&:name)  
      self.decrypted_columns = encrypted_columns.collect{|col| col.chomp suffix }
      decrypted_columns.each { |col| attr_accessor col }
      
      before_save :encrypt_columns
      
      secret   = YAML.load_file(Rails.root + "/config/#{key_file}")[Rails.env].symbolize_keys
      self.key = EzCrypto::Key.with_password secret[:key], secret[:salt]
    end
    def key_encrypt_and_encode(value)
      return nil if value.nil?
      key.encrypt64 value
    end
    def key_encrypt(value)
      return nil if value.nil?
      key.encrypt value
    end
    
    def key_decode_and_decrypt(value)
      return nil if value.nil?
      key.decrypt64 value
    end
    def key_decrypt(value)
      key.decrypt value
    rescue OpenSSL::CipherError
      return nil
    end
  end
  
  
  module InstanceMethods
    def encrypt_columns
      self.class.decrypted_columns.each do |col|
        send "#{col}#{self.class.suffix}=", self.class.key_encrypt_and_encode(eval(col))
      end
    end
    
    # Have to call it like this for performance reasons
    # http://api.rubyonrails.org/classes/ActiveRecord/Callbacks.html
    def after_find
      decrypt_columns
    end
    
    def decrypt_columns
      self.class.encrypted_columns.each do |col|
        send "#{col.chomp self.class.suffix}=", self.class.key_decode_and_decrypt(eval(col))
      end
    end
    
  end
  
end