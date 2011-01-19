["db:create", "db:seed"].each do |task|
  Rake::Task[task].clear if Rake::Task.task_defined? task
end
namespace :db do
  task :create => :environment do
    create_domain(ActiveRecord::Base.configurations[Rails.env])
  end

  task :seed => :environment do
    seed_file = File.join(Rails.root, 'db', 'seeds.rb')
    if File.exist?(seed_file)
      Rails.logger.info "Push data from seeds file to domain"
      load(seed_file) 
    else
      Rails.logger.info "Seeds file (#{seed_file}) not found"
    end
  end

  def create_domain(config)
    ActiveRecord::Base.establish_connection(config)
    domain_name = config[:domain_name] || config['domain_name']
    Rails.logger.info "Create sdb domain #{domain_name}"
    ActiveRecord::Base.connection.create_domain(domain_name)
  end
end
