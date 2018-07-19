# # Modules: Sidekiq
# Adds settings and tasks for managing Sidekiq workers.
#
# ## Usage example
#     require 'mina_sidekiq/tasks'
#     ...

#     task :setup do
#       # sidekiq needs a place to store its pid file
#       command %[mkdir -p "#{fetch(:deploy_to)}/shared/pids/"]
#     end
#
#     task :deploy do
#       deploy do
#         invoke :'git:clone'
#         invoke :'sidekiq:quiet'
#         invoke :'deploy:link_shared_paths'
#         ...
#
#         to :launch do
#           ...
#           invoke :'sidekiq:restart'
#         end
#       end
#     end

# ## Settings
# Any and all of these settings can be overriden in your `deploy.rb`.

# ### sidekiq
# Sets the path to sidekiq.
set :sidekiq, -> { "#{fetch(:bundle_bin)} exec sidekiq" }

# ### sidekiqctl
# Sets the path to sidekiqctl.
set :sidekiqctl, -> { "#{fetch(:bundle_prefix)} sidekiqctl" }

# ### sidekiq_timeout
# Sets a upper limit of time a process is allowed to finish, before it is killed by sidekiqctl.
set :sidekiq_timeout, 11

# ### sidekiq_config
# Sets the path to the configuration file of sidekiq
set :sidekiq_config, -> { "#{fetch(:current_path)}/config/sidekiq/sidekiq.yml" }

# ### sidekiq_log
# Sets the path to the log file of sidekiq
#
# To disable logging set it to "/dev/null"
set :sidekiq_log, -> { "#{fetch(:current_path)}/log/sidekiq.log" }

# ### sidekiq_pid
# Sets the path to the pid file of a sidekiq worker
set :sidekiq_pid, -> { "#{fetch(:current_path)}/tmp/pids/sidekiq.pid" }

# ### sidekiq_processes
# Sets the number of sidekiq processes launched
set :sidekiq_processes, %w(default info market trade)

# ## Control Tasks
namespace :sidekiq do
  def for_each_process(&block)
    fetch(:sidekiq_processes).each.with_index do |name, idx|
      cfg_file = "#{fetch(:sidekiq_config)}-#{name}"
      pid_file = "#{fetch(:sidekiq_pid)}-#{name}"
      log_file = "#{fetch(:sidekiq_log)}-#{name}"
      yield(pid_file, cfg_file, log_file, idx)
    end
  end

  # ### sidekiq:quiet
  desc "Quiet sidekiq (stop accepting new work)"
  task :quiet => :remote_environment do
    comment 'Quiet sidekiq (stop accepting new work)'
    in_path(fetch(:current_path)) do
      for_each_process do |pid_file|
        command %{
          if [ -f #{pid_file} ] && kill -0 `cat #{pid_file}` > /dev/null 2>&1; then
            #{fetch(:sidekiqctl)} quiet #{pid_file}
          else
            echo 'Skip quiet command (no pid file found)'
          fi
        }.strip
      end
    end
  end

  # ### sidekiq:stop
  desc "Stop sidekiq"
  task :stop => :remote_environment do
    comment 'Stop sidekiq'
    in_path(fetch(:current_path)) do
      for_each_process do |pid_file|
        command %{
          if [ -f #{pid_file} ] && kill -0 `cat #{pid_file}`> /dev/null 2>&1; then
            #{fetch(:sidekiqctl)} stop #{pid_file} #{fetch(:sidekiq_timeout)}
          else
            echo 'Skip stopping sidekiq (no pid file found)'
          fi
        }.strip
      end
    end
  end

  # ### sidekiq:start
  desc "Start sidekiq"
  task :start => :remote_environment do
    comment 'Start sidekiq'
    in_path(fetch(:current_path)) do
      for_each_process do |pid_file, cfg_file, log_file, idx|
        command %[echo '#{fetch(:sidekiq)} -d -e #{fetch(:rails_env)} -C #{cfg_file} -i #{idx} -P #{pid_file} -L #{log_file}']
        command %[#{fetch(:sidekiq)} -d -e #{fetch(:rails_env)} -C #{cfg_file} -i #{idx} -P #{pid_file} -L #{log_file}]
      end
    end
  end

  # ### sidekiq:restart
  desc "Restart sidekiq"
  task :restart do
    invoke :'sidekiq:stop'
    invoke :'sidekiq:start'
  end

  desc "Tail log from server"
  task :log => :remote_environment do
    command %[tail -f #{fetch(:sidekiq_log)}]
  end
end
