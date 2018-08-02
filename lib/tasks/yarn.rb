set :yarn_bin, 'yarn'
set :yarn_options, '--production'

namespace :yarn do
  desc 'Install node modules using Yarn.'
  task install: :remote_environment do
    comment 'Installing node modules using Yarn'
    in_path(fetch(:current_path)) do
      command %[#{fetch(:yarn_bin)} install --modules-folder #{fetch(:shared_path)}/node_modules #{fetch(:yarn_options)}]
    end
  end
end