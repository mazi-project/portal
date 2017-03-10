require "helpers/mazi_exec_cmd"

module Mazi::Model
  class Application < Sequel::Model
    one_to_many :application_instances
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
      case self.name.downcase 
      when 'nextcloud'
        return 'ON'
      when 'guestbook'
        nm = 'mazi-board'
      else
        nm = self.name.downcase
      end

      ex = MaziExecCmd.new('sh', '/root/back-end/', 'mazi-app.sh', ['-a', 'status', nm], ['mazi-app.sh'], 'normal')
      lines = ex.exec_command
      case lines.first
      when 'active'
        return 'ON'
      when 'inactive'
        return 'OFF'
      end
      return 'FAIL'
    end

    def start
      case self.name.downcase 
      when 'nextcloud'
        return 'ON'
      when 'guestbook'
        nm = 'mazi-board'
      else
        nm = self.name.downcase
      end

      ex = MaziExecCmd.new('sh', '/root/back-end/', 'mazi-app.sh', ['-a', 'start', nm], ['mazi-app.sh'], 'normal')
      ex.exec_command

      "OK"
    end

    def stop
      case self.name.downcase 
      when 'nextcloud'
        return 'ON'
      when 'guestbook'
        nm = 'mazi-board'
      else
        nm = self.name.downcase
      end

      ex = MaziExecCmd.new('sh', '/root/back-end/', 'mazi-app.sh', ['-a', 'stop', nm], ['mazi-app.sh'], 'normal')
      ex.exec_command

      "OK"
    end
  end
end