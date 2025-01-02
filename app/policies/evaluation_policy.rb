class EvaluationPolicy < ApplicationPolicy
  def show?
    course_admin?
  end

  def create?
    course_admin?
  end

  def update?
    course_admin?
  end

  def add_users?
    course_admin?
  end

  def manage_scores?
    course_admin?
  end

  def destroy?
    course_admin?
  end

  def overview?
    record.users.include?(user) && record.released
  end

  def set_multi_user?
    course_admin?
  end

  def add_user?
    course_admin?
  end

  def remove_user?
    course_admin?
  end

  def mark_undecided_complete?
    course_admin?
  end

  def export_grades?
    course_admin?
  end

  def modify_grading_visibility?
    course_admin?
  end

  def permitted_attributes
    if record.instance_of?(Evaluation)
      %i[released deadline user_ids exercise_ids]
    else
      %i[series_id deadline user_ids exercise_ids]
    end
  end

  private

  def course_admin?
    return false unless user
    return false unless record

    user.course_admin?(record.series.course)
  end
end
