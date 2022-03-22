$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require "minitest/autorun"
require "active_record"
require "logger"
require "activerecord-intersys-adapter"

unless binding.respond_to? :pry
  class Binding; def pry; puts("Stray pry binding!"); end; end
end

ActiveRecord::Base.configurations = {
  "test" => {
    adapter: "intersys",
    namespace: "TEST",
    package: "Test",
    host: "winchester.hmgrain.com",
    port: "2008",
    user: "_SYSTEM",
    password: "SYS"
  }
}

ActiveRecord::Base.pluralize_table_names = false
ActiveRecord::Base.logger = Logger.new("debug.log")
ActiveRecord::Base.establish_connection "test"

class TimeStamp < Intersys::Serial::Object; end

class Person < ActiveRecord::Base
  has_many :comments
  has_many :jobs
  has_many :companies, through: :jobs
end

class Comment < ActiveRecord::Base
  belongs_to :person
end

class Job < ActiveRecord::Base
  belongs_to :person
  belongs_to :company
end

class Company < ActiveRecord::Base
  has_many :jobs
  has_many :people, through: :jobs

  default_scope select: [:id, :name, :street_address]
end

MICHAEL = {first_name: "Michael", last_name: "Scott"}
DWIGHT  = {first_name: "Dwight", last_name: "Schrute"}
CREED   = {first_name: "Creed", last_name: "Bratton", age: 60, weight: 185.7}
PAM     = {first_name: "Pam", last_name: "Halper"}
JIM     = {first_name: "Jim", last_name: "Beesly"}
DMI     = {name: "Dunder Miflin", street_address: "1725 Slough Avenue"}
