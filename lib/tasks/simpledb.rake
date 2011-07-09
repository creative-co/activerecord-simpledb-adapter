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
  task :setup => [:recreate, :import, :seed]

  desc "Export collections from sdb to seeds.yml"
  task :export, [:collections]=> :environment do |t, args|
    collections = args[:collections].try(:split, ',')
    data = ActiveSupport::OrderedHash.new
    if collections
      collections.each do |c|
        data[c] = []
        c.classify.constantize.all.each { |item| data[c] << item.attributes }
      end
      File.open(dump_file, "w") do |out|
        YAML.dump(data, out)
      end
    else
        log "Please put collections name as \"collections=<first>,<second>...\""
    end
  end

  desc "Import collections from seeds.yml to sdb"
  task :import => :environment do
    if File.exists? dump_file
      data = YAML.load_file(dump_file)
      data.each_pair do |entity, values|
        cls = entity.classify.constantize
        cls.destroy_all

        values.each { |val|
          created_obj = cls.create! val
        }
      end
      log "Data from seeds.yml file was pushed to domain"
    else
      log "File seeds.yml not found. Import skipped."
    end
  end

  namespace :collection do
    desc "Clear all data for collection by name"
    task :clear, [:name] => :environment do |t, args|
      name = args[:name]
      if name.present?
        count = 0
        Kernel.const_get(name.capitalize).all.each do |item|
          item.destroy
          count += 1
        end
        log "#{count} items was deleted."
      else
        log "Please put collection name as \"name=<collection_name>\""
      end
    end
  end

  def create_domain
    ActiveRecord::Base.connection.create_domain(domain_name)
    log "Sdb domain \"#{domain_name}\" was created"
  end

  def domain_name
    conf[:domain_name] || conf['domain_name']
  end
  
  def conf
    @conf ||= ActiveRecord::Base.configurations[Rails.env]
  end

  def log text
    puts text
  end

  def dump_file
    @dump_file ||= File.join(Rails.root, 'db', 'seeds.yml')
  end
end
