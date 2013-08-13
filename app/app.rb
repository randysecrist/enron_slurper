ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$:.unshift(File.join(ROOT_DIR, "app"))
$:.unshift(File.join(ROOT_DIR, 'lib'))

require 'bundler'
Bundler.require(:default)

module Enron
  module API
    def self.registered(app)
      app.set :prefixes, []
      app.set :versions, []
    end

    # condition helper useful for before blocks
    # before :prefixed => '/internal'
    def prefixed(p)
      condition { env['enron.api.prefix'] == p }
    end

    # Specify the prefix for the application
    # prefix '/data/source'
    def prefix(*ps)
      set :prefixes, ps.map { |p| ::File.join("/", p) }
    end

    # Specify the version for the application
    # version 'v1'
    def version(*vs)
      set :versions, vs.map { |v| ::File.join("/", v) }
    end

    # prefixed routes must be specified as strings
    def new_paths(path, block)
      if path.nil? || path.respond_to?(:to_str)
        vs = versions.empty? ? ["/"] : versions
        ps = prefixes.empty? ? ["/"] : prefixes

        vs.product(ps).map do |v, p|
          new_block = Proc.new { env['enron.api.version']=v; env['enron.api.prefix']=p; instance_eval &block }
          new_path = case path
                     when "/"
                       ::File.join(v, p)
                     when "*", nil
                       ::File.join(v, p) + "*"
                     else
                       ::File.join(v, p, path)
                     end
          [new_path, new_block]
        end
      else
        [path, block]
      end
    end

    def get(path, opts={}, &bk) new_paths(path, bk).each { |np, nb| super np, opts, &nb } end
    def put(path, opts={}, &bk) new_paths(path, bk).each { |np, nb| super np, opts, &nb } end
    def post(path, opts={}, &bk) new_paths(path, bk).each { |np, nb| super np, opts, &nb } end
    def delete(path, opts={}, &bk) new_paths(path, bk).each { |np, nb| super np, opts, &nb } end
    def head(path, opts={}, &bk) new_paths(path, bk).each { |np, nb| super np, opts, &nb } end
    def options(path, opts={}, &bk) new_paths(path, bk).each { |np, nb| super np, opts, &nb } end
    def patch(path, opts={}, &bk) new_paths(path, bk).each { |np, nb| super np, opts, &nb } end

    def before(path=nil, opts={}, &bk)
      path, opts = nil, path if path.respond_to?(:each_pair)
      new_paths(path, bk).each { |np, nb| super np, opts, &nb }
    end

    def after(path=nil, opts={}, &bk)
      path, opts = nil, path if path.respond_to?(:each_pair)
      new_paths(path, bk).each { |np, nb| super np, opts, &nb }
    end

  end

  Sinatra.register API

end

require 'ripple'
require 'sinatra/base'
require 'sinatra/url_for'
require 'pbkdf2'

require 'log4r'

# ripple
Ripple.load_config(File.join(ROOT_DIR,'config','ripple.yml'), [ENV['RACK_ENV']])


WorkerLogger =  Log4r::Logger.new 'worker_logger'
WorkerLogger.outputters = Log4r::FileOutputter.new('fileOutputter',
                                                   :filename => "log/workers.log",
                                                   :trunc => false,
                                                   :formatter =>  Log4r::PatternFormatter.new(:pattern => "%d %l %m"))

require 'ripple-encryption'

# setup load path
$:.unshift File.dirname(__FILE__)

# Require core overloads

class ApiServer < Sinatra::Base
  extend Settings

  set :show_exceptions, false
  set :raise_errors, %w( test ).include?(ENV['RACK_ENV'])

  not_found do
    send_sinatra_file('404.html') {"Sorry, I cannot find #{request.path}"}
  end

  configure do
    enable_encryption = ApiServer.setting(:enable_encryption)
    if enable_encryption
      Ripple::Encryption.activate(File.join(ROOT_DIR,'config','encryption.yml'))
    end
  end

  error do
    raise env['sinatra.error']
  end

  def send_sinatra_file(path, &missing_file_block)
    file_path = File.join(File.dirname(__FILE__), '../doc',  path)
    file_path = File.join(file_path, 'index.html') unless file_path =~ /\.[a-z]+$/i
    File.exist?(file_path) ? send_file(file_path) : missing_file_block.call
  end
end

require 'exceptions/models'

require 'helpers/ripple'
require 'helpers/email'
require 'helpers/enron_api'


# require all the models and behaviors
FileList[File.join(ROOT_DIR,'app','models','behaviors','*.rb')].each{|f| require f}
FileList[File.join(ROOT_DIR,'app','models','*.rb')].each{|f| require f}

require 'resque'

# redis
redis_cfg = YAML.load_file(File.join(ROOT_DIR, 'config', 'redis.yml'))[ENV['RACK_ENV']].symbolize_keys
Resque.redis = Redis.new(redis_cfg)

require 'workers/post_worker'

require 'routes/api/v1'


