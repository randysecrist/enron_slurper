module API
  module V1
    class Email < Sinatra::Base
      register Enron::API
    
      version 'v1'
      prefix '/email'
    
      before do
        content_type 'application/json'
      end
    
      # read from disk
      get '/:person/:mailbox/:email_id' do
        person = params[:person]
        mailbox = params[:mailbox]
        mail = Mail.read("#{ApiServer.setting(:enron_data_path)}/#{person}/#{mailbox}/#{params[:email_id]}")
        mail.person = person
        mail.mailbox = mailbox
        mail.to_json({key: "#{person}#{Mail::Message::DELIMITER}#{mailbox}"})
      end

      # read from search
      # http://localhost:8098/solr/email/select?q=(body_raw:send AND customer_id:lay-k)&wt=json

      # read from search using inline filter
      # http://localhost:8098/solr/email/select?q=body_raw:send&wt=json&filter=customer_id:lay-k

      put '/' do
        begin
          doc = JSON.parse request.env['rack.input'].read
        rescue Exception => e
          puts e.inspect
        end
        # puts doc
        status 204
      end

    end
  end
end

