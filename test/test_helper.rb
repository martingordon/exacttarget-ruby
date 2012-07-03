require 'test/unit'
require 'turn'
require 'shoulda'

require 'et'

Savon.configure { |config| config.log = false }

HTTPI.log = false

def log_savon(&block)
  Savon.configure { |config| config.log = true }
  block.call()
  Savon.configure { |config| config.log = false }
end

def reset_all
  types = []

  types.each do |type|
    objs = type.find
    type.destroy(objs) if objs.count > 0
  end
end
