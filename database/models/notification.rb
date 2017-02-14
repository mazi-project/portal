module Mazi::Model
  class Notification < Sequel::Model
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