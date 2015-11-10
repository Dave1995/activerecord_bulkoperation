class Student < ActiveRecord::Base  
  has_and_belongs_to_many :courses,:association_primary_key => 'the_other_student_id',:association_foreign_key => 'the_other_course_id',:join_table => "students_related_courses",:primary_key => 'student_id',:foreign_key => 'course_id'
end