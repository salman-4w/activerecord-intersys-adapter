require "rake/testtask"

task :default => "test:all"

namespace "test" do
  test_files = FileList["test/**/*_test.rb"]
  integration_test_files = FileList["test/**/*integration_test.rb"]
  unit_test_files = test_files - integration_test_files

  desc "Run unit tests"
  Rake::TestTask.new("units") do |t|
    t.libs.push "lib"
    t.libs.push "test"
    t.test_files = unit_test_files
    t.verbose = true
  end

  desc "Run integration tests"
  Rake::TestTask.new("integration") do |t|
    t.libs.push "lib"
    t.libs.push "test"
    t.test_files = integration_test_files
    t.verbose = true
  end

  desc "Run all tests"
  task "all" => %w[test:units test:integration]
end

namespace "ext" do
  desc "Compiles and moves bundle to lib directory for use"
  task "compile" do
    Dir.chdir("ext") do
      system "make && mv intersys_bindings.bundle ../lib"
    end
  end
end
