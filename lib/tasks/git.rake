# ## Control Tasks
namespace :git do
  # ### git:precompile
  desc "Precompile webpack"
  task :precompile => :environment do
    # system('git reset .')
    # system('git rm public/packs/*')
    # system('RAILS_ENV=production bundle exec rake assets:precompile')
    # system('git add public/packs/*')
    status = %x[git status]
    if status.include?('no changes added to commit')
      puts 'no changes, skip commit'
    else
      system('git commit -m "webpacker precompile"')
      system('git push origin master')
    end
  end
end
