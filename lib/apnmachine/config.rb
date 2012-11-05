module ApnMachine
  class Config
    class << self
      attr_accessor :redis, :logger, :queue
    end
  end
end
