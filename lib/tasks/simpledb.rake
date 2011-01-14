Rake::Task['db:create'].clear
Rake::Task['db:seed'].clear
namespace :db do
  task :create => :load_config do
    create_domain(ActiveRecord::Base.configurations[Rails.env])
  end

  task :seed => :environment do
    seed_file = File.join(Rails.root, 'db', 'seeds.rb')
    load(seed_file) if File.exist?(seed_file)
  end

  def create_domain(config)
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Base.connection.create_domain(config['domain_name'])
  end
end
