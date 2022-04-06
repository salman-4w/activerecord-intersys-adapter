# TODO: add AR & intersys dependences and documentation
# TODO: create a README file
# PKG_RDOC_OPTS = ["--main=README",
#                  "--line-numbers",
#                  "--charset=utf-8",
#                  "--promiscuous"]

Gem::Specification.new do |s|
  s.name = "activerecord-intersys-adapter"
  s.version = "0.4.0"
  s.author = "Anton Dyachuk"
  s.email = "anton.dyachuk@gmail.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "Intersystems Cache adapter for ActiveRecord"
  s.files = Dir["lib/**/*", "ext/**/*"]
  s.require_path = "lib"
  s.has_rdoc = false
  s.add_dependency "activerecord", ">= 3.2.3"
  s.extensions << "ext/extconf.rb"
end
