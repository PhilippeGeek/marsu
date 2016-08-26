class StudyYear < ApplicationRecord

  has_many :students

  validates_presence_of :year
  validates_presence_of :name
  validates_uniqueness_of :name

end
