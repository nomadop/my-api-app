# ## Control Tasks
namespace :git do
  # ### git:precompile
  desc "Precompile webpack"
  task :precompile => :environment do
    system('git reset .')
    system('rm -f public/packs/*')
    system('git rm --ignore-unmatch -f public/packs/*')
    system('RAILS_ENV=production bundle exec rake assets:precompile')
    system('git add public/packs/*')
    status = %x[git status]
    status.include?('no changes added to commit') ?
      puts('no changes, skip commit') :
      system('git commit -m "webpacker precompile"')
  end
end
