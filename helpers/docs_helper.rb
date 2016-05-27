module DocsHelper
  def documentation_path(page, version=nil)
    "/#{version || current_version}/#{page}.html"
  end

  def link_to_documentation(page)
    link_to page.gsub('_', ' '), documentation_path(page)
  end

  def path_exist?(page, version=nil)
    sitemap.find_resource_by_path(documentation_path(page, version))
  end

  def other_commands(primary_commands, version=nil)
    version ||= current_version

    current_pages = sitemap.resources.select do |page|
      page.path.start_with?("#{version}/bundle_")
    end

    commands = current_pages.map{ |page| page.path[(version.length + 1)..-6] }

    (commands - primary_commands).sort
  end
end
