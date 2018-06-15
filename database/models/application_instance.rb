module Mazi::Model
  class ApplicationInstance < Sequel::Model
    many_to_one :application
    # validate if there is something missing in the
    # returns nil if it is OK, else it returns the key that is missing
    def self.validate(description={})
      description['application_id'] = description.delete('application') if description['application']
      mandatory_keys = ['name', 'url', 'application_id', 'color']
      mandatory_keys.each do |key|
        return key if description[key].nil? || description[key].empty?
      end
      valid_keys = ['name', 'description', 'url', 'application_id', 'color', 'icon']
      description.each do |key|
        description.delete_if {|k, v| !valid_keys.include?(k) }
      end
      description['click_counter'] = 0
      description['enabled'] ||= true
      nil
    end

    # validate if there is something missing in the
    # returns nil if it is OK, else it returns the key that is missing
    def self.validate_edit(description={})
      mandatory_keys = ['id', 'name', 'description', 'url', 'color']
      mandatory_keys.each do |key|
        return key if description[key].nil? || description[key].empty?
      end
      valid_keys = ['id', 'name', 'description', 'url', 'enabled', 'color', 'icon']
      description.each do |key|
        description.delete_if {|k, v| !valid_keys.include?(k) }
      end
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
  end
end
