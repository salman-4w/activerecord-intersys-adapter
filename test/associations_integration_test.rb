require "helper"

class AssociationsIntegrationTest < MiniTest::Unit::TestCase
  def test_has_many_and_belongs_to
    jim = Person.create JIM
    assert_equal 0, jim.comments.count
    jim.comments << Comment.new(content: "Bears eat beets.")
    jim.save
    assert_equal 1, jim.comments.length
    comment = jim.comments.first
    assert comment.id
    assert_equal comment, Comment.find(comment)
    assert_equal jim, comment.person
    assert_raises ActiveRecord::DeleteRestrictionError do
      jim.destroy
    end
  end

  def test_has_many_through
    ms = Person.create MICHAEL
    company1 = Company.create name: "Dunder Miflin"
    company2 = Company.create name: "Michael Scott Paper Company"
    manager = Job.create title: "Manager", company: company1, person: ms
    founder = Job.new title: "Founder"
    founder.person = ms
    founder.company = company2
    founder.save
    assert_equal 2, ms.jobs.count
    assert_equal 1, company1.people.count
    assert_equal 1, company2.people.count
    assert ms.companies.include? company1
    assert ms.companies.include? company2
  end

  def test_belongs_to_preload
    dmi = Company.create! DMI
    job = Job.create! title: "Receptionist", company: dmi
    relation = Company.where(id: dmi).includes(:jobs)
    assert_equal job, relation.first.jobs.first
  end

  def teardown
    [Job, Comment, Company, Person].each { |klass| klass.delete_all }
  end
end
