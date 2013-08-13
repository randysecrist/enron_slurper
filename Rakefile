require 'rubygems'
gem 'bundler'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

namespace(:test) do
  desc "Test everything"
  task :all => [:test] + Dir["vendor/*"].map { |d| "test:#{File.basename(d)}" }

  Dir["vendor/*"].each do |vendor_dir|
    vendor = File.basename(vendor_dir)
    Rake::TestTask.new(vendor) do |test|
      test.libs << vendor_dir + '/lib'
      test.libs << vendor_dir + '/test'
      test.pattern = vendor_dir + '/test/**/test_*.rb'
      test.verbose = true
    end
  end
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "att #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

def load_messaging_deps
  $:.unshift(File.join(File.dirname(__FILE__), "app"))

  # Bundler
  ENV['BUNDLE_GEMFILE'] = File.join( File.expand_path(File.dirname(__FILE__)), "Gemfile" )
  require 'rubygems'
  require 'bundler'
  Bundler.setup

  require 'find'
  require 'mail'
  require 'json'
  require 'faraday'
  require 'time'
  require 'log4r'
  require 'riak'

  require 'app'
end

task :resque_environment do
  load_messaging_deps
end

require 'resque/tasks'
namespace :resque do
  DEFAULTS = {
      "QUEUE" => "email_publisher",
      "WORKER_COUNT" => "24",
  }
  DEFAULTS.each do |default_key,default_value|
    ENV[default_key] = ENV[default_key] || default_value
  end

  require 'yaml'
  settings = YAML.load_file(File.expand_path("config/settings.yml", File.dirname(__FILE__)))[ENV["RACK_ENV"]]

  ENVIRONMENT_ARGS = "RACK_ENV=#{ENV["RACK_ENV"]} QUEUE=#{ENV["QUEUE"]}"

  desc "setup resque environment"
  task setup: :resque_environment

  desc "status"
  task :status do
    (1..ENV['WORKER_COUNT'].to_i).each do |i|
      pidfile = "log/api_resque_worker_#{i}.pid"
      pid = get_pid pidfile, "resque"
      pid_running? pid if pid
    end
  end

  desc "start workers"
  task :start => [:setup] do
    (1..ENV['WORKER_COUNT'].to_i).each do |i|
      pidfile = "log/api_resque_worker_#{i}.pid"
      pid = get_pid pidfile
      pid_running? pid if pid

      unless pid
        puts "starting worker #{i}"
        log_file = 'log/resque.stdout.log'
        resque_command = "nohup bundle exec rake resque:work --trace  >> #{log_file} &"
        environment = "#{ENVIRONMENT_ARGS} ACTOR=#{i} PIDFILE=#{pidfile}"
        %x{ #{environment} #{resque_command} }
      end
    end
  end

  desc "stop workers"
  task :stop do
    (1..ENV['WORKER_COUNT'].to_i).each do |i|
      pidfile = "log/api_resque_worker_#{i}.pid"

      pid = get_pid pidfile

      if pid && pid_running?(pid)
        puts "stopping #{pid}"
        Process.kill("QUIT", pid) rescue puts "unable to kill #{pid}"
      end

      if File.exists? pidfile
        puts "deleting #{pidfile}"
        FileUtils.rm(pidfile) rescue puts "unable to delete #{pidfile}"
      end
    end
  end
  desc "restart workers"
  task :restart => [:stop, :start]
end

def pid_running? pid
  begin
    Process.getpgid( pid.to_i )
    puts "#{pid} is running"
    true
  rescue Errno::ESRCH
    puts "#{pid} is not running"
    false
  end
end

def proc_info name, col
  consumer_command = "ps aux | grep #{name} | grep -v grep | grep -v #{Process.pid} | head -n1 | awk \"{ print \\$#{col} }\""
  info = %x{#{consumer_command}}
  if info == ""
    false
  else
    info.strip
  end
end

def get_pid file, check_proc = false
  if File.exists? file
    puts "Found #{file}"
    IO.read(file).to_i
  else
    puts "#{file} doesn't exist"

    if check_proc
      proc = proc_info check_proc, 11
      pid = proc_info check_proc, 2

      if !proc || !pid
        puts "No processes found matching #{check_proc}"
        false
      else
        puts "Found #{proc} with pid = #{pid}"
        pid
      end
    else
      false
    end
  end
end
