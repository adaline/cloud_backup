#!/usr/bin/env ruby
# encoding: utf-8
$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))

require 'rubygems'
require 'cocaine'
require 'get_config'
require 'fog'
require 'active_support/core_ext'

class Backup
	@db_config = GetConfig::get('db')
	@databases = @db_config["databases"]
	@threshold = @db_config["backlog"].to_i.days.ago
	@backup_prefix = @db_config["backup_prefix"]

	@aws_config = GetConfig::get('aws')
	@fog = Fog::Storage.new(
		:provider => @aws_config['provider'],
		:aws_access_key_id => @aws_config['aws_access_key_id'],
		:aws_secret_access_key => @aws_config['aws_secret_access_key'],
		:region => @aws_config['region']).directories.get(@aws_config['bucket'])

	def self.backup()
		# create a file to backup, name it with a date stamp + backup name
		# upload it to AWS
		# delete old file(s) from AWS
		mysql_params = []
		mysql_params << "-u:user"
		mysql_params << "-p:password"
		mysql_params << "-h:host"
		mysql_params << "-Q"
		mysql_params << "-c"
		mysql_params << "-C"
		mysql_params << "--quick"
		mysql_params << ":db"
		mysql_params << "> :file"

		bzip2_params = []
		bzip2_params << "-z"
		bzip2_params << "-9"
		bzip2_params << "-f"
		bzip2_params << ":source"	

		@databases.each do |db|
			sql_file = File.join @db_config['dir'], db +"_"+ Time.now.strftime("%d_%m_%Y") + '.sql'
			mysql_options = {:user => @db_config['user'], :password => @db_config['password'], :host => @db_config['host'], :db => db, :file => sql_file}
			run('mysqldump', mysql_params, mysql_options)

			if File.exists? sql_file

				bzip2_file = db +"_"+ Time.now.strftime("%d_%m_%Y") + '.sql.bz2'
				bzip2_path = File.join @db_config['dir'], bzip2_file
				bzip2_options = {:source => sql_file}
				run('bzip2', bzip2_params, bzip2_options)

				if File.exists? bzip2_path
					file = @fog.files.new(
						:key    => "#{@backup_prefix}/#{bzip2_file}",
						:body   => File.open(bzip2_path),
						:public => false
					)
					file.save
				end
			end
		end
		@fog.files.all(:prefix => "#{@backup_prefix}/").each do |file|
			if file.last_modified < @threshold
				file.destroy
			end
		end
	end

	private

	def self.run(command, params, options)
		begin
			params = params.flatten.compact.join(" ").strip.squeeze(" ")
			line = Cocaine::CommandLine.new(command, params, options)
			line.run
		rescue Cocaine::ExitStatusError => e
			puts "There was an error running #{command}"
		rescue Cocaine::CommandNotFoundError => e
			puts "Could not run the #{command} command. You may need to instal whatever package #{command} is from."
		end
	end
end


Backup.backup