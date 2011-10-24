Cloud backup
------------

I made this script out of a need to backup MySQL db from VPS servers, but it should be very easy to make it backup anything else.


### Install

#### Clone this repo to desired location:
```
git clone git://github.com/adaline/cloud_backup.git
cd cloud_backup
```

#### Install all the gems
```
bundle install
```

#### Edit config files
config/aws.yaml - contains the credentials for cloud storage, I use AWS but you can change it to any provider supported by fog.io
config/db.yaml - contains db credentials needed to run mysqldump, list of databases you want to backup, how long to keep the backlog (30 days) and the prefix for the files (eg. server1)
config/schedule.rb - "Whenever" config file, please change the `:backup` job type to whatever you need, i have it set up to use rvm. (http://github.com/javan/whenever)

#### Set up cron
Run whenever to write crontab:
```
whenever -w
```
View crontab to confirm an added command:
```
crontab -l
```

#### Remove from crontab
To remove the script form your crontab and stop it running periodically run:
```
whenever -c
```