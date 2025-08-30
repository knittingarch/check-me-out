class Book < ApplicationRecord
  enum status: { available: 0, checked_out: 1, reserved: 2 }
end
