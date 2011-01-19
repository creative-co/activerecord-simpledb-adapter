#clear all predefined db tasks
Rake::Task.tasks.select{ |task| task.name.match /db:/ }.each { |task| task.clear }
namespace :db do
  desc "Create the SimpleDB domain"
  task :create => :environment do
    create_domain
  end

  desc "Drop the SimpleDB domain"
  task :drop => :environment do
    con = ActiveRecord::Base.connection
    if con.list_domains.include? domain_name
      con.delete_domain(domain_name) 
      log "Domain \"#{domain_name}\" was dropped"
    end
  end

  desc "Drop and create the SimpleDB domain"
  task :recreate => [:drop, :create] 

  desc "Load the seed data from db/seeds.rb"
  task :seed => :environment do
    seed_file = File.join(Rails.root, 'db', 'seeds.rb')
    if File.exist?(seed_file)
      load(seed_file) 
      log "Data from seeds file was pushed to domain"
    else
      log "Seeds file (#{seed_file}) not found"
    end
  end

  desc "Re-create the domain and initialize with the seed data"
  task :setup => [:recreate, :seed]

  namespace :collection do
    desc "Clear all data for collection by name"
    task :clear, [:name, :ccn] => :environment do |t, args|
      ccn = args[:ccn] || 'collection'
      name = args[:name]
      if name.present?
        rows = ActiveRecord::Base.connection.select_all("SELECT id FROM `#{domain_name}` WHERE `#{ccn}` = '#{name}'")
        rows.each do |row|
          ActiveRecord::Base.connection.execute({
            :action => :delete,
            :wheres => {:id => row['id']}
          })
          log "#{row.count} items was deleted."
        end
      else
        log "Please put collection name as \"name=<collection_name>\""
      end
    end
  end

  def create_domain
    ActiveRecord::Base.connection.create_domain(domain_name)
    log "Sdb domain \"#{domain_name}\" was created"
  end

  def config
    @config ||= ActiveRecord::Base.configurations[Rails.env]
  end

  def domain_name
    config[:domain_name] || config['domain_name']
  end

  def log text
    Rails.logger.info text
  end
end
