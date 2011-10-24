# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

job_type :backup, "cd :path && rvm 1.9.2 do bundle exec ruby :task :output"

every 1.day, :at => '6:00 am' do 
  backup "backup.rb"
end

# Learn more: http://github.com/javan/whenever
