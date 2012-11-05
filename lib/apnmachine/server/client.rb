module ApnMachine
  module Server
    class Client
      attr_accessor :pem, :apn_host, :password, :key, :cert, :close_callback

      def initialize(pem, password = nil, apn_sandbox = false)
        @pem, @pasword = pem, password
        @apn_host = apn_sandbox ? 'gateway.sandbox.push.apple.com' : 'gateway.push.apple.com'
      end

      def connect!
        raise "The path to your pem file is not set." unless @pem
        raise "The path to your pem file does not exist!" unless File.exist?(@pem)
        @key, @cert = @pem, @pem
        Config.logger.debug "Connecting to #{apn_host}"
        @connection = EM.connect(apn_host, 2195, ApnMachine::Server::ServerConnection, self)
      end
        
      def disconnect!
        @connection.close_connection
      end

      def write(notif_bin)
        @connection.send_data(notif_bin)
      end

      def connected?
        @connection.connected?
      end
    
      def on_error(&block)
        @error_callback = block
      end

      def on_close(&block)
        @close_callback = block
      end
      
    end #client
  end #server
end #apnmachine
