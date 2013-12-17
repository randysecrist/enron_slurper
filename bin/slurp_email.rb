require 'find'
require 'mail'
require 'json'
require 'faraday'
require 'time'
require 'log4r'
require 'riak'

require_relative '../app/app'
require_relative '../app/helpers/email'
require_relative '../app/helpers/enron_api'

SlurpLogger = Log4r::Logger.new 'worker_logger'
SlurpLogger.outputters = Log4r::FileOutputter.new('fileOutputter',
                                                  :filename => "log/slurp_email.log",
                                                  :trunc => false,
                                                  :formatter =>  Log4r::PatternFormatter.new(:pattern => "%d %l %m"))

person = 'lay-k'
mailbox = 'inbox'

data_path = ApiServer.setting(:enron_data_path)

@batch_size = 1
@send_count = 0
@batch = []
@visited = {}

def batch_files(path)
  parts = path.split('/')
  person = parts[parts.length - 3]
  mailbox = parts[parts.length - 2]

  return if mailbox != 'inbox'

  # only scan the inbox
  SlurpLogger.info "Scanning: #{person}/#{mailbox}" unless @visited["#{person}/#{mailbox}"]
  @visited["#{person}/#{mailbox}"] = true

  # reset
  if @send_count >= @batch_size
    @batch = []
    @send_count = 0
  end

  # increment
  @batch.push(path)
  @send_count += 1

  # Fire Async
  Enron::Async::EmailWorker.enqueue(@batch, person, mailbox) if @batch.length == @batch.size
end

dirs = [data_path]
excludes = []
dirs.each do |dir|
  Find.find(dir) do |path|
    Find.prune if excludes.include?(File.basename(path))
    batch_files path if ! FileTest.directory?(path)
  end
end

# fire any remainder
read_and_fire(@batch, person, mailbox) unless @send_count >= @batch_size # may have hit a batch boundary on last Find
