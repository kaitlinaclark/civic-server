class Drug < ActiveRecord::Base
  has_many :evidence_items
end
