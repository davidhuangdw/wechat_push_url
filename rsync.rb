# source: http://pastebin.com/viMSaRh3
# Invoke rsync when there are changes in the current directory

# 1. Change to project root, `cd /Users/joelam/Projects/tabs`
# 2. Initial rsync local to VM, `rsync -avzi -e ssh . deploy@joelam.dev.cloud.vitrue.com:/home/deploy/Projects/Vitrue/tabs/`
# 3. Please place this file in project_root (e.g. /Users/joelam/Projects/tabs/)
# 4. Run the script by `ruby fsevent_rsync.rb`
# 5. Modify any file in directory
# 6. rsync is executed, modified files are copied to VM

require 'rubygems'
require 'rb-fsevent'
require 'open3'

include Open3

options = { :latency => 2 }

host = "mzou.dev.cloud.vitrue.com"
data_path = "/data/push_url"
# local folders to sync
folders = %w(
  *
).join(" ")

# exclude patterns
exclude_patterns = %w(
  fsevent_rsync.rb
  rsync.rb
  tmp/***
  public/media
  public/stylesheets/*.css
  public/stylesheets/jquery/*.css
  public/stylesheets/oocss/*.css
  public/stylesheets/legacy
  public/javascripts/apps/*_build/***
  public/javascripts/translations.js
  public/javascripts/i18n/***
  db/***
  .idea/***
  *.log
  .DS_Store
  .idea/*
  .rvmrc
  tmp/***
  .git/***
  )

rsync_exclude_options = exclude_patterns.map { |p| "--exclude='#{p}'" }.join(' ')

rsync = "rsync -avzit --delete -e ssh #{rsync_exclude_options} #{folders} deploy@#{host}:#{data_path}"

def run_with_output command
  popen3(command) do |stdin, stdout, stderr|
    stdout.read.split("\n").map { |line|
      puts "rsync: #{line}"
    }
  end
end

# initialize the sync before monitoring
run_with_output rsync

# monitoring changes
fsevent = FSEvent.new
fsevent.watch Dir.pwd, options do |directories|
  puts "Detected change inside: #{directories.inspect}"
  run_with_output rsync
end
fsevent.run