# Cocina Food Inspector

This project will attempt to pass existing digital repository objects from Fedora through `Cocina::Mapper` by using the `Objects#show` route of dor-services-app.  Results will be logged.

# HOWTO

## show a druid using this project's rails console

1. clone this project, `bundle install`
1. clone shared_configs, checkout the branch for this project, and copy `config/settings/production.yml` to the corresponding location in this project's working dir (it's in the `.gitignore` so that it's harder to accidentally commit)
1. `RAILS_ENV=production be rails c`
1. 
```ruby
[1] pry(main)> require('dsa_client')
=> true
[2] pry(main)> DsaClient.object_show('druid:bb000kg4251')
=> #<Faraday::Response:0x00007ff09051c100 ...lots of stuff... >
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
