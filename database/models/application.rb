 
module Mazi::Model
  class Application < Sequel::Model
    # validate if there is something missing in the 
    # returns nil if it is OK, else it returns the key that is missing
    def self.validate(description={})
      mandatory_keys = ['name', 'description', 'url']
      mandatory_keys.each do |key|
        return key if description[key].nil? || description[key].empty?
      end
      valid_keys = ['name', 'description', 'url']
      description.each do |key|
        description.delete_if {|k, v| !valid_keys.include?(k) }  
      end
      description['click_counter'] = 0
      nil
    end

    # validate if there is something missing in the 
    # returns nil if it is OK, else it returns the key that is missing
    def self.validate_edit(description={})
      mandatory_keys = ['id', 'name', 'description', 'url']
      mandatory_keys.each do |key|
        return key if description[key].nil? || description[key].empty?
      end
      valid_keys = ['id', 'name', 'description', 'url', 'enabled']
      description.each do |key|
        description.delete_if {|k, v| !valid_keys.include?(k) }  
      end
      description['click_counter'] = 0
      description['enabled'] ||= true
      nil
    end

    def enable
      self.enabled = true
      self.save
    end

    def disable
      self.enabled = false
      self.save
    end

    def status
      "ON"
    end

    def start
      "OK"
    end

    def stop
      "OK"
    end
  end
end