
task :merge_users, [:arg1, :arg2] => :environment do |task, args|
  u1_id = args[:arg1].to_i
  u2_id = args[:arg2].to_i

  MergeUsers.new.merge_users_interactive u1_id, u2_id
end
