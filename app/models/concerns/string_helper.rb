module StringHelper
  extend ActiveSupport::Concern

  # returns the first string argument that is not nil or blank
  # if nothing is satisfying, returns 'n/a'
  def first_string_present(*args)
    args.each do |arg|
      return arg unless arg.nil? || arg.blank?
    end
    'n/a'
  end
end
