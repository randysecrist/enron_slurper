# Enron eMail Slurper

This project uses [Riak](http://github.com/basho/riak) + [Redis](https://github.com/redis/redis-rb) + [Ruby](https://github.com/ruby/ruby) + [Resque](http://github.com/resque/resque) to ingest (slurp) up the now public Enron email corpus and allow it to be queried with riak's full text search.

The slurper works by recursively listing directories and files; queuing (in redis).  Workers pull things out of redis and post (into **riak** via **HTTP**) one file at a time.

By default the Rakefile will fire up several (24ish) resque workers just to get some decent concurrency going.

## Usage

There are several steps needed to get going.  This assumes you know how to get ruby, riak, and redis up and going.

1)  Checkout with `git clone` and execute:

    $ bundle
    
2)  Download and untar the enron corpus:

    $ ./bin/get_enron_data_set.sh; tar -xzf enron_mail_20110402.tar.gz
    
3)  Enable riak search & set the schema for the email bucket:

    $ /path/to/riak/bin/search-cmd install email
    $ /path/to/riak/bin/search-cmd set-schema email lib/enron_email_poc_schema.erl

4)  Review Slurper Configs:

In particular pay attention to the ```redis.yml``` and ```settings.yml```.

The ```settings.yml``` contains these keys:

	# path to enron data set
    :enron_data_path: 'enron_mail_20110402/maildir'
    
    # base riak url to post to
    :email_url: 'http://localhost:8098/riak'
    
5)  Fire up the email slurper:

    $ RACK_ENV=development bundle exec ruby bin/slurp.rb

6)  Fire up a bunch of resque workers to load up Riak:

    $ RACK_ENV=development bundle exec rake resque:start

7)  Wait for it to finish; (it processes the directories in alphabetical order).  Progress can be monitored from ```log/workers.log``` file or by asking Resque how deep its queue is.  Be sure to remember to stop all those resque workers when done!

    $ RACK_ENV=development bundle exec rake resque:stop
    
8)  Finally; query riak using full text search:

```bash
curl -s 'http://localhost:8098/solr/email/select?q=body_raw:send&wt=json&filter=customer_id:lay-k'
```

## Running the Tests

Adjust the 'test/fixtures/ripple.yml' to point to a test riak database.

    bundle exec rake
