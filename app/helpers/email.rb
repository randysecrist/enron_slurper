# Make it easy to convert RFC822 to JSON
module Mail
  class Message

    # DELIMITER = "\x1f"
    DELIMITER = ','

    attr_accessor :person, :mailbox

    # keyed by
    # customer-id | mailbox | message-id
    def message_id
      id = header.fields.detect do |x|
        x.name == 'Message-ID'
      end.to_s
      id = id[1..id.length-1].match /^\d+\.\d+/
      id.to_s
    end

    def date
      date = header.fields.detect do |x|
        x.name == 'Date'
      end.to_s
      Time.parse(date).to_i
    end

    def to_json(opts = {})
      hash = {}

      hash['customer_id'] = @person unless @person.nil?
      hash['mailbox'] = @mailbox unless @mailbox.nil?
      hash['timestamp'] = date
      hash['message_id'] = message_id

      # headers
      hash['headers'] = {}
      allowed = ['Date', 'From', 'To', 'Subject']
      header.fields.each do |field|
        hash['headers'][field.name] = field.value if allowed.include?(field.name)
      end
      special_variables = [:@header]

      # limit to just body, use detect or something to short circut
      hash['body_raw'] = instance_variable_get('@body_raw')
      # (instance_variables.map(&:to_sym) - special_variables).each do |var|
        # hash[var.to_s] = instance_variable_get(var) # send all the things
      # end

      begin
        hash.to_json(opts)
      rescue Exception => e
        puts "Warning:  #{e.inspect}"
        '' # for now; toss bad characters
      end
    end        
  end
end