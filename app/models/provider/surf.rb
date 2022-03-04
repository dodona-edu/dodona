class Provider::Surf < Provider::Oidc

  def self.sym
    :surf
  end

  SURF_SUFFIX = '.nl'.freeze

  def self.extract_institution_name(auth_hash)
    institution = auth_hash&.extra&.raw_info&.schac_home_organization

    # Sanity check
    return Provider.extract_institution_name(auth_hash) unless institution =~ URI::DEFAULT_PARSER.make_regexp

    uri = URI.parse(institution)
    host = uri.host
    return Provider.extract_institution_name(auth_hash) unless host.end_with?(SURF_SUFFIX)

    school_name = host.delete_suffix SURF_SUFFIX
    [school_name, school_name]
  end
end
