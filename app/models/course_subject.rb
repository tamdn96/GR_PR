class CourseSubject < ApplicationRecord
  belongs_to :course
  belongs_to :subject

  validates :course_id, uniqueness: { scope: :subject_id }

  scope :in_progress, -> {where status: "in_progress"}
  default_scope ->{order(date_start: :asc)}

  enum status: [:init, :in_progress, :finish, :block]
end
