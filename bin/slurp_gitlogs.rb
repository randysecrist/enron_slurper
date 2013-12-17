#! /usr/bin/env ruby

require 'commander/import'
require 'grit'
require 'json'

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

      results = []
      commits.each do |commit|
        results << build(commit)
      end
      puts results.to_json

    end
  end

  def self.build(commit)
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
