
module Enron
  module Async

    class EmailWorker
      @queue = :email_publisher

      @api = EnronAPI.new({:url_encode => true})

      # this worker has the responsibiliy of forwarding messages to rabbitmq
      def self.perform(batch, person, mailbox)
        WorkerLogger.info "Sending: #{person}/#{mailbox}"
        begin
          @api.read_and_fire(batch, person, mailbox)
        rescue Exception => e
          WorkerLogger.error "Error Sending: #{e.inspect}"
        end
      end

      def self.enqueue(batch, person, mailbox)
        Resque.enqueue self, batch, person, mailbox
      end
    end

  end
end
