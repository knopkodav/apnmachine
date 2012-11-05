require 'yajl' unless defined?(Yajl)

module ApnMachine
  class Notification

    attr_accessor :device_token, :alert, :badge, :sound, :custom

    PAYLOAD_MAX_BYTES = 256
    class PayloadTooLarge < StandardError;end
    class NoDeviceToken < StandardError;end

    def encode_payload
      p = {:aps => Hash.new}
      [:badge, :alert, :sound].each do |k|
        p[:aps][k] = send(k) if send(k)
      end
      p.merge!(custom) if send(:custom)

      j = Yajl::Encoder.encode(p)
      raise PayloadTooLarge.new("The payload is larger than allowed: #{j.length}") if j.size > PAYLOAD_MAX_BYTES

      p[:device_token] = device_token
      raise NoDeviceToken.new("No device token") unless device_token

      Yajl::Encoder.encode(p)
    end

    def push queue = nil
      raise 'No Redis client' if Config.redis.nil?
      queue = queue || Config.queue
      Config.logger.debug "Pushing message | QUEUE:#{queue}"
      socket = Config.redis.rpush(queue, encode_payload)
    end

    def self.to_bytes(encoded_payload)
      notif_hash = Yajl::Parser.parse(encoded_payload)

      device_token = notif_hash.delete('device_token')
      raise NoDeviceToken.new("No device token") unless device_token

      j = Yajl::Encoder.encode(notif_hash)
      raise PayloadTooLarge.new("The payload is larger than allowed: #{j.length}") if j.size > PAYLOAD_MAX_BYTES

      Config.logger.debug "TOKEN:#{device_token} | ALERT:#{j}"

      # bin_token = [device_token].pack('H*')
      # [0, 0, bin_token.size, bin_token, 0, j.size, j].pack("ccca*cca*")

      [1, 0, 86400, 0, 32, device_token, 0, j.size, j].pack("cNNccH*cca*")      
    end

  end

end
