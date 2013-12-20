#! /usr/bin/env ruby

require 'commander/import'
require 'grit'
require 'json'
require 'riak_json'

module GitSlurper

  program :name, 'slurp_gitlog'
  program :version, '0.0.1'
  program :description, 'Slurp git logs into a format acceptable to RIAK + SOLR'

  default_command :slurp

  command :slurp do |c|
    c.syntax = 'slurp_gitlog <repo> <branch>'
    c.description = 'dump the git log to JSON format for <repo> and <branch>'
    #c.option '--repo Repository', String, 'Path to Git Repository'
    #c.option '--branch Branch', String, 'Git Branch to use, defaults to \'master\''
    c.when_called do |args, options|
      unless args.length == 2
        puts 'Wrong number of arguments; <repo> <branch>'
        exit(1)
      end

      repo = Grit::Repo.new(args.first)
      # may timeout
      #commits = repo.commits(args.last, repo.commit_count)

      options = { max_count: repo.commit_count, skip: 0, timeout: false }
      commits = Grit::Commit.find_all(repo, args.last, options)

      rj_client = RiakJson::Client.new('localhost', 10018)
      #commit_collection = rj_client.collection("#{args.first}_#{args.last}_commits")
      commit_collection = rj_client.collection("test1_commits")

      define_schema(commit_collection) unless commit_collection.has_schema?

      commits.each do |commit|
        document = RiakJson::Document.new
        document.body = serialize(commit)
        commit_collection.insert(document)
        puts commit.id
      end

    end
  end

  def self.define_schema(collection)
    schema = RiakJson::CollectionSchema.new
    schema.add_string_field(name='author', required=true)
    schema.add_string_field(name='committer', required=true)
    schema.add_text_field(name='message')
    schema.add_integer_field(name='stats.additions', required=true)
    schema.add_integer_field(name='stats.deletions', required=true)
    schema.add_integer_field(name='stats.total', required=true)
    schema.add_multi_string_field(name='stats.files.path')
    collection.set_schema(schema)
  end

  def self.serialize(commit)
    stats = commit.stats
    {
      id: commit.id,
      parents: commit.parents,
      author: commit.author,
      authored_date: commit.authored_date,
      committer: commit.committer,
      committed_date: commit.committed_date,
      message: commit.message,
      stats: {
        files: stats.files.map do |file|
          {
            path: file[0],
            additions: file[1],
            deletions: file[2],
            total: file[3]
          }
        end,
        additions: stats.additions,
        deletions: stats.deletions,
        total: stats.total
      }
    }
  end

end
