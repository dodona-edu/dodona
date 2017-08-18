module RepositoryHelper
  def github_link(repository, path = nil, name: nil)
    url = repository.github_url(path)
    name ||= path || repository.name
    if url
      link_to name, url
    else
      name
    end
  end
end
