# Cocina Food Inspector

This project will attempt to pass existing digital repository objects from Fedora through `Cocina::Mapper` by using the `Objects#show` route of dor-services-app.  Results will be logged.

# HOWTO

## show a druid using this project's rails console

1. clone this project, `bundle install`
1. clone shared_configs, checkout the branch for this project, and copy `config/settings/production.yml` to the corresponding location in this project's working dir (it's in the `.gitignore` so that it's harder to accidentally commit)
1. if you are running this from your laptop, sign onto the VPN
1. `RAILS_ENV=production be rails c`
1. 
```ruby
[1] pry(main)> CocinaDruidRetriever.try_retrieval_and_log_result('druid:bb000kg4251') # will also write success message to prod log, and maybe log full response output as json
=> #<Faraday::Response:0x00007ff09051c100 ...lots of stuff... >
```

### file output

#### server logs

The result of each attempted request is sent to the server logs for the instance being run.  Some example output:

```log
I, [2020-03-25T17:05:36.866312 #1292]  INFO -- : retrieving druid:bb000kg4251
I, [2020-03-25T17:05:37.774728 #1292]  INFO -- : success: 200 OK retrieving druid:bb000kg4251
I, [2020-03-25T17:05:51.910169 #1292]  INFO -- : retrieving druid:bb100kg4259
W, [2020-03-25T17:05:52.085807 #1292]  WARN -- : failure: 404 Not Found retrieving druid:bb100kg4259 : Unable to find 'druid:bb100kg4259' in fedora. See logger for details.
I, [2020-03-25T17:06:09.929235 #1292]  INFO -- : retrieving druid:bb100kg425
W, [2020-03-25T17:06:10.075075 #1292]  WARN -- : failure: 400 Bad Request retrieving druid:bb100kg425 : {"errors":[{"status":"bad_request","detail":"#/components/schemas/Druid pattern ^druid:[b-df-hjkmnp-tv-z]{2}[0-9]{3}[b-df-hjkmnp-tv-z]{2}[0-9]{4}$ does not match value: druid:bb100kg425, example: druid:bc123df4567"}]}
```

* lines 1 & 2 (for `druid:bb000kg4251`) are a simple success message.  There were no errors attempting to render the object as a Cocina model.
* lines 3 & 4 (for `druid:bb100kg4259`) are a 404: dor-services-app could not find the object in Fedora.
* lines 5 & 6 (for `druid:bb100kg425`) is a 400 bad request:  dor-services-app didn't even attempt to look up the druid, because the "druid" supplied to it isn't of the right format.
* _Not yet sure what a conversion error looks like -- assume it's a 500 of some sort?  Haven't run into an unconvertible druid yet._

#### file system output

By default, the full response is only logged for requests that fail.  However, in production, when testing for real, we may want to log output for all requests, and do some sort of validation or manual spot checking to see that the Cocina model is what we consider a valid translation of the Fedora data.  Output for the successful retrievals can be obtained by turning the `cocina_output.success.should_output` setting to `true`.

File system output is organize by whether its cocina model output (TODO: retrieve Fedora output directly using dor-services for comparison as described above), whether dor-services-app responded successfully or not, then by druid, then by date (since a given druid may be attempted multiple times).  Example:

```
$ tree log/cocina_output/
log/cocina_output/
├── failure
│   ├── druid:bb000kg425
│   │   ├── 2020-03-25T23:38:37Z.json
│   │   └── 2020-03-25T23:41:31Z.json
│   ├── druid:bb100kg425
│   │   ├── 2020-03-25T23:44:50Z.json
│   │   ├── 2020-03-26T00:06:10Z.json
│   │   └── 2020-03-26T00:20:38Z.json
│   └── druid:bb100kg4259
│       ├── 2020-03-25T23:41:47Z.json
│       ├── 2020-03-25T23:44:24Z.json
│       └── 2020-03-26T00:05:52Z.json
└── success
    └── druid:bb000kg4251
        └── 2020-03-26T00:21:01Z.json

6 directories, 9 files
```

## get a list of all druids in fedora

uses this script from argo:  https://github.com/sul-dlss/argo/blob/master/bin/dump_fedora_pids.rb

```sh
$ ssh lyberadmin@sul-dor-prod ruby dump_fedora_pids.rb # assumes you have a valid kerb ticket and access to sul-dor-prod as lyberadmin

pid dump should be in /tmp/all_pids_2020-03-25_01:33:07
$
$ scp lyberadmin@sul-dor-prod:'/tmp/all_pids_2020-03-25_01:33:07' .
all_pids_2020-03-25_01:33:07                                                               100%   35MB 336.6KB/s   01:46
$
```

## load druids from a file into the DB

In rails console:

```ruby
# can remove either or both limits if desired, default is to just do try adding whole input file.  dupes will be ignored.
Druid.add_new_druids_from_file('all_pids_2020-03-25_01:33:07', limit_readlines: 1000, limit_adds: 2000)

# might take a while if you do a file with all the druids
Druid.add_new_druids_from_file('all_pids_2020-03-25_01:33:07')
```

## grab 10 druids that we have not yet recorded any events for in the DB

You can build on this example to find batches of things to queue up for inspection once you've adequately populated the druid list per the above instructions.

```ruby
[19] pry(main)> Druid.where.not(id: DruidRetrievalAttempt.select(:druid_id).distinct).limit(10).pluck(:druid)
   (0.4ms)  SELECT  "druids"."druid" FROM "druids" WHERE "druids"."id" NOT IN (SELECT DISTINCT "druid_retrieval_attempts"."druid_id" FROM "druid_retrieval_attempts") LIMIT ?  [["LIMIT", 10]]
=> ["changeme:4",
 "changeme:5",
 "druid:bb000kq3835",
 "druid:bb000zn0114",
 "druid:bb001bb1008",
 "druid:bb001dq8600",
 "druid:bb001mf4282",
 "druid:bb001nx1648",
 "druid:bb001pn1602",
 "druid:bb001xb8305"]
```

### use a canned version of this to try to retrieve druids we haven't seen yet

```
[1] pry(main)> CocinaDruidRetriever.try_retrieving_unseen_druids(max_to_retrieve: 5)
/Users/suntzu/.rbenv/versions/2.7.0/lib/ruby/gems/2.7.0/gems/activemodel-5.2.4.2/lib/active_model/type/value.rb:8: warning: The called method `initialize' is defined here
  Druid Load (0.5ms)  SELECT  "druids".* FROM "druids" WHERE "druids"."id" NOT IN (SELECT DISTINCT "druid_retrieval_attempts"."druid_id" FROM "druid_retrieval_attempts") ORDER BY "druids"."id" ASC LIMIT ?  [["LIMIT", 5]]
retrieving druid:bb001mf4282
success: 200 OK retrieving druid:bb001mf4282
Unexpected error trying to retrieve druid:bb001mf4282 and log result: "\xC3" from ASCII-8BIT to UTF-8
retrieving druid:bb003dn0409
success: 200 OK retrieving druid:bb003dn0409
Unexpected error trying to retrieve druid:bb003dn0409 and log result: "\xC2" from ASCII-8BIT to UTF-8
retrieving druid:bb006ys3871
success: 200 OK retrieving druid:bb006ys3871
Unexpected error trying to retrieve druid:bb006ys3871 and log result: "\xC2" from ASCII-8BIT to UTF-8
retrieving druid:bb008kd6296
success: 200 OK retrieving druid:bb008kd6296
  Druid Load (0.2ms)  SELECT  "druids".* FROM "druids" WHERE "druids"."druid" = ? LIMIT ?  [["druid", "druid:bb008kd6296"], ["LIMIT", 1]]
  Druid Load (0.3ms)  SELECT  "druids".* FROM "druids" WHERE "druids"."id" = ? LIMIT ?  [["id", 38], ["LIMIT", 1]]
   (0.1ms)  begin transaction
  DruidRetrievalAttempt Create (0.5ms)  INSERT INTO "druid_retrieval_attempts" ("druid_id", "response_status", "response_reason_phrase", "output_path", "created_at", "updated_at") VALUES (?, ?, ?, ?, ?, ?)  [["druid_id", 38], ["response_status", 200], ["response_reason_phrase", "OK"], ["output_path", "log/cocina_output/success/druid:bb008kd6296/2020-03-26T05:34:42Z.json"], ["created_at", "2020-03-26 05:34:42.584797"], ["updated_at", "2020-03-26 05:34:42.584797"]]
   (0.8ms)  commit transaction
retrieving druid:bb008rc3511
failure: 500 Internal Server Error retrieving druid:bb008rc3511 : {"status":500,"error":"Internal Server Error"}
  Druid Load (0.1ms)  SELECT  "druids".* FROM "druids" WHERE "druids"."druid" = ? LIMIT ?  [["druid", "druid:bb008rc3511"], ["LIMIT", 1]]
  Druid Load (0.1ms)  SELECT  "druids".* FROM "druids" WHERE "druids"."id" = ? LIMIT ?  [["id", 39], ["LIMIT", 1]]
   (0.0ms)  begin transaction
  DruidRetrievalAttempt Create (0.4ms)  INSERT INTO "druid_retrieval_attempts" ("druid_id", "response_status", "response_reason_phrase", "output_path", "created_at", "updated_at") VALUES (?, ?, ?, ?, ?, ?)  [["druid_id", 39], ["response_status", 500], ["response_reason_phrase", "Internal Server Error"], ["output_path", "log/cocina_output/failure/druid:bb008rc3511/2020-03-26T05:34:42Z.json"], ["created_at", "2020-03-26 05:34:42.939230"], ["updated_at", "2020-03-26 05:34:42.939230"]]
   (3.1ms)  commit transaction
=> nil
```

Omit the `max_to_retrieve` param, and it defaults to 200.  That default is configurable via `Settings.max_unseen_druids_to_retrieve`.

### how many unretrieved druids are left in the DB?

```ruby
Druid.unretrieved.count
```

## run this code on the shared deployment environment (a.k.a. how to run this on john's burndown box)



## run tests on this codebase

Just hacking something together to start and trying to run it against some prod data to get a sense of what responses will look like, and what info seems useful to collect as we start to scale.  So for now, you can manually test basic usage (200, 400, 404 for some known druids) from rails console.  Use the instructions above and these druids:
* `druid:bb000kg4251` -- expected 200 OK
* `druid:bb100kg4259` -- expected 4040 Not Found
* `druid:bb000kg425` -- expected 400 Bad Request (invalid druid format)

Make sure you don't get any unexpected exceptions, make sure the logs look right, make sure the file output looks right.
