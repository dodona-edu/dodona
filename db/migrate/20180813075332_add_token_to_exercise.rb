class AddTokenToExercise < ActiveRecord::Migration[5.1]
  def change
    add_column :exercises, :token, :string, :limit => 64
    add_index :exercises, :token, unique: true

    exercises = Exercise.all
    exercises.each do |exercise|
      exercise.generate_token
      if exercise.ok?
        c = exercise.config
        if c
          c['internals'] = {}
          c['internals']['token'] = exercise.token
          c['internals']['_info'] = 'These fields are used for internal bookkeeping in Dodona, please do not change them.'
          exercise.config_file.write(JSON.pretty_generate c)
        else
          exercise.status = :removed
        end
      end
      exercise.save
    end
    repositories = Repository.all
    repositories.each do |repository|
      repository.commit 'add internal tokens to all exercises'
    end
  end
end
