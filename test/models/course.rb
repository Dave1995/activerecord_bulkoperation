class Course < ActiveRecord::Base
  has_and_belongs_to_many :students,:association_primary_key => :the_other_course_id,:association_foreign_key => :the_other_student_id,:join_table => "students_related_courses",:primary_key => :course_id,:foreign_key => :student_id
end