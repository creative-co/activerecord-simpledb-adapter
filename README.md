# ABOUT

Amazon SimpleDB Adapter for ActiveRecord for Rails3

# FEATURES

- All data saves in one sdb domain (each activerecord model class detected by special reserved column 'collection')
- Columns with numbers (integer and float) saves with special shift and constant size for correcting comparation in SELECT query.

# USAGE

install:

    gem install activerecord-simpledb-adapter

config/database.yml:

	defaults: &defaults
	  adapter: simpledb
	  access_key_id: KEY
	  secret_access_key: SECRET
    development:
	  <<: *defaults
	  domain_name: domain_name

for creating domain:
    
	rake db:create

model example:
    Person < ActiveRecord::Base
	  columns_definition do |t|
	    t.string :login
	    t.integer :year, :limit => 4
	    t.boolean :active
	    t.string :from
	    t.float :price
	    t.integer :lock_version

	    t.timestamps
	  end
	end

# TODO

- Add some howtos to wiki
- Rewrite rails model generator

# LICENSE

(The MIT License)

Copyright ©  Ilia Ablamonov, Alex Gorkunov, Cloud Castle Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ‘Software’), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
