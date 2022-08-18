class PrepareForPersonalUsers < ActiveRecord::Migration[7.0]
  def up
    # Mark existing office 365 identities as legacy
    Identity.joins(:provider).where(provider: {type: "Provider::Office365"}).update_all(identifier_based_on_email: true)

    # create personal providers
    Provider::Office365.create identifier: '9188040d-6c67-4c5b-b112-36a304b66dad', institution: nil
    Provider::GSuite.create identifier: nil, institution: nil
  end

  def down
    # Remove personal providers
    Provider.where(institution: nil).destroy_all

    # Remove legacy mark
    Identity.joins(:provider).where(provider: {type: "Provider::Office365"}).update_all(identifier_based_on_email: false)
  end
end
