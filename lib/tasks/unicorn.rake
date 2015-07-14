namespace :unicorn do
  task :start do
    `bundle exec unicorn -Dc push_url_unicorn.rb`
  end
  task :kill do
    `cat tmp/unicorn.pid | xargs -- kill`
  end
  task :show do
    puts `ps aux | grep --color=always unicorn`
  end
  task :restart => [:kill, :start]
end
