class CourseMembershipStatusDefault < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      admin = CourseMembership.statuses['course_admin']
      student = CourseMembership.statuses['student']
      dir.up do
        CourseMembership
          .joins(:user)
          .where(users: { permission: %w[zeus staff] })
          .update_all("course_memberships.status = #{admin}")
        CourseMembership
          .joins(:user)
          .where(users: { permission: 'student' })
          .update_all("course_memberships.status = #{student}")
        change_column_default :course_memberships, :status, student
      end
      dir.down do
        change_column_default :course_memberships, :status, nil
        CourseMembership.update_all(status: nil)
      end
    end
  end
end
