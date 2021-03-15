require "ostruct"

class AddGeneratedNameToInstitutions < ActiveRecord::Migration[6.0]
  def change
    add_column :institutions, :generated_name, :boolean, default: true, null: false

    reversible do |dir|
      dir.up do
        Institution.where.not(name: 'n/a').update_all(generated_name: false)
        # Update existing institutions if there is a preferred provider.
        # Only for GSuite & Smartschool, since the rest is a lot of work]
        Institution.joins(:providers)
                   .where(generated_name: true)
                   .where(providers: { type: %w[Provider::GSuite Provider::Smartschool] })
                   .each do |institution|
          provider = institution.preferred_provider
          auth_hash = OpenStruct.new(info: OpenStruct.new(institution: provider.identifier))
          long, short = provider.class.extract_institution_name(auth_hash)
          institution.update_columns(name: long, short_name: short)
        end
      end
      dir.down do
        Institution.joins(:providers)
                   .where(generated_name: true)
                   .where(providers: { type: %w[Provider::GSuite Provider::Smartschool] })
                   .update_all(
                     name: Institution::NEW_INSTITUTION_NAME,
                     short_name: Institution::NEW_INSTITUTION_NAME
                   )
      end
    end
  end
end
