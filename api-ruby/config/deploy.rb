# Change the 'YOUR_AZURE_VM_IP' to the publicIpAddress from the output of
# `az vm create` command executed above
require 'json'
role :app, JSON.parse(`az vmss list-instance-connection-info -g level1 -n level1-vmss`)

# Change the YOUR_GITHUB_NAME to your github user name
set :repo_url,        'git@github.com:devigned/level1.git'
set :repo_tree,       'api-ruby'
set :application,     'level1'
set :user,            'deploy'
set :puma_threads,    [4, 16]
set :puma_workers,    0

# Don't change these unless you know what you're doing
set :pty,             true
set :use_sudo,        false
set :stage,           :production
set :deploy_via,      :remote_cache
set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.access.log"
set :puma_error_log,  "#{release_path}/log/puma.error.log"
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
      execute "mkdir #{release_path}/log -p"       
    end
  end

  before :start, :make_dirs
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/master`
        puts "WARNING: HEAD is not the same as origin/master"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc 'Build and Ember Assets' 
  task :build_ember do
    on roles(:app) do
      api_host = `az network public-ip show -g level1 -n level1-vmss --query 'dnsSettings.fqdn' -o tsv`.strip
      cmd = <<-CMD
      cd '#{release_path}/todo-ember' &&  \
      npm install --no-progress > log.txt 2>&1 && \
      sed -i 's/{{ API_HOST }}/http:\\/\\/#{api_host}/g' config/environment.js && \
      CDN_HOST=http://$(az cdn endpoint list -g level1 --profile-name level1 --query '[0] | hostName' -o tsv)/ ./node_modules/ember-cli/bin/ember build --silent --environment production && \
      rm -rf ../public/* && \
      cp -R dist/* ../public
CMD
       execute cmd
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      invoke 'deploy'
      execute "sudo rm -f /etc/nginx/sites-enabled/default"
      execute "sudo ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/level1"
      execute "sudo service nginx restart"
    end
  end

  before :starting,     :check_revision
  after  :finishing,    :build_ember
  after  :finishing,    :cleanup
end

# ps aux | grep puma    # Get puma pid
# kill -s SIGUSR2 pid   # Restart puma
# kill -s SIGTERM pid   # Stop puma