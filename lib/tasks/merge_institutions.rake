task :merge_institutions, [:arg1, :arg2] => :environment do |task, args|
  i1_id = args[:arg1].to_i
  i2_id = args[:arg2].to_i

  require_relative 'merge_institutions.rb'
  MergeInstitutions.new.merge_institutions_interactive(i1_id, i2_id)
end
