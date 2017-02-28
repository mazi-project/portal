require 'securerandom'

module Mazi::Model
  class Session < Sequel::Model
    def after_create
      self.created_at = Time.now
      self.uuid = SecureRandom.uuid
      self.save
    end
  end
end