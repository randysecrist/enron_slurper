class EnronAPI

  def initialize(opts = {})
    @url_encode = opts[:url_encode]
 
    # Write to Riak Directly via POST
    @base_uri = ApiServer.setting(:email_url)

    @connection = Faraday.new url: @base_uri do |builder|
      builder.use Faraday::Request::UrlEncoded if @url_encode
      builder.adapter :net_http
    end
  end

  def get(path, params={})
    results = @connection.get(path, params)
    JSON.parse(results.body)
  end

  def put(path, data={})
    data = data.to_json unless @url_encode
    response = @connection.put(path, data) do |request|
      # set this or the precommit indexer won't know what to do
      request.headers['Content-Type'] = 'application/json'
    end
    return response
  end

  def post(path, data={})
    data = data.to_json unless @url_encode
    response = @connection.post(path, data)
    return response
  end

  def delete(path)
    response = @connection.delete(path)
  end

  def read_and_fire(file_list, person, mailbox)
    payload = file_list.map do |file|
      mail = Mail.read(file)
      mail.person = person
      mail.mailbox = mailbox
      mail
    end

    if payload.length == 1
      payload = payload[0]
      key = "#{person}_#{payload.date}"
    else
      key = "#{person}_#{payload.first.date}"
    end

    WorkerLogger.info "Reading and posting: #{person}/#{mailbox}/#{key}"

    json = payload.to_json.force_encoding("UTF-8")

    # write_to_file(json)

    post_json(key, json)
  end

  def post_json(key, value)
    begin
      response = put("/riak/email/#{key}", value)
      if response.status != 204
        WorkerLogger.error "Post Response: - #{response.status}"
        # https://github.com/rack/rack/issues/337
        # https://github.com/rack/rack/commit/decaa23a175d2fc65b4bc103e7fff0027e3eb21c
      end
    rescue Exception => e
      WorkerLogger.error "Problem with key: #{key} - #{e.inspect}"
    end
    (response.nil?) ? nil : response.status
  end

  def write_to_file(json)
    File.write('out.json', json)
  end

end


