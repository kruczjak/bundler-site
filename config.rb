Dir.glob(File.expand_path('../lib/config/*.rb', __FILE__), &method(:require))

config[:versions] = `rake versions`.split
config[:current_version] = config[:versions].last

activate :syntax
activate :i18n
activate :sprockets
activate :search do |search|
  search.resources = ['index.html', "#{config[:current_version]}/"]

  search.index_path = 'search/lunr-index.json'

  search.fields = {
    title: {boost: 100, store: true, required: true},
    content: {boost: 50},
    url: {index: false, store: true},
    description: {index: false, store: true},
  }
end

set :markdown_engine, :kramdown

# Markdown extentions
set :markdown,
    autolink: true,
    fenced_code_blocks: true,
    footnotes: true,
    gh_codeblock: true,
    highlight: true,
    no_intra_emphasis: true,
    quote: true,
    smartypants: true,
    strikethrough: true,
    superscript: true,
    tables: true

set :javascript_dir, 'javascripts'
set :css_dir, 'stylesheets'
set :images_dir, 'images'

# Make documentation for the latest version available at the top level, too.
# Any pages with names that conflict with files already at the top level will be skipped.
Dir.glob("./source/#{config[:current_version]}/**/*").select{ |f| !File.directory? f }.each do |file_path|
  file_path = file_path[0..-6] if file_path[-5..-1] == '.haml'
  file_path = file_path[0..-4] if file_path[-3..-1] == '.md'

  page_path = file_path["./source/".length..-1]
  proxy_path = file_path["./source/#{config[:current_version]}/".length..-1]

  proxy proxy_path, page_path unless file_exist?(proxy_path)
end
# Same for localizable
Dir.glob("./source/localizable/#{config[:current_version]}/**/*").select{ |f| !File.directory? f }.each do |file_path|
  matched = file_path.match(/(localizable\/v\d+.\d+\/(.*)\.(.{2})\.html)/)
  next unless matched

  page_path = matched[1]
  proxy_path = "#{matched[2]}.html"
  country = matched[3]

  next if file_exist?(proxy_path)

  proxy "#{country}/#{proxy_path}", page_path, locale: country.to_sym
  proxy proxy_path, page_path, locale: :en if country == 'en'
end

# Proxy man generated documentation to be available at /vX.XX/ (for compatibility with old guides)
# Ex: /v1.12/man/bundle-install.1.html.erb available at /v1.12/bundle_install.html
config[:versions].each do |version|
  Dir.glob("./source/#{version}/man/**/*").select{ |f| !File.directory? f }.each do |file_path|
    file_path = file_path[0..-5]
    page_path = file_path["./source".length..-1]

    man_page_name_matched = file_path.match(/man\/(.*)\.html$/)
    next unless man_page_name_matched

    man_page_name = man_page_name_matched[1].gsub(/\.\d+$/, '').gsub('-', '_')
    man_page_name = 'gemfile_man' if man_page_name == 'gemfile'

    proxy "/#{version}/#{man_page_name}.html", page_path unless man_page_exists?(man_page_name, version)
  end
end

page '/sponsors.html', layout: :compatibility_layout
page '/conduct.html', layout: :guides_layout
page '/older_versions.html', layout: :guides_layout
page '/compatibility.html', layout: :guides_layout
page /\/v(\d+.\d+)\/(?!bundle_|commands|docs|man)(.*)/, layout: :md_guides_layout
page /\/v(.*)\/bundle_(.*)/, layout: :commands_layout
page /\/v(.*)\/man\/(.*)/, layout: :commands_layout
page /\/man\/(.*)/, layout: :commands_layout
page /\/v(.*)\/commands\.html/, layout: :commands_layout
page /\/v(.*)\/guides\/(.*)/, layout: :md_guides_layout

page '/sitemap.xml', layout: false

###
# Helpers
###
Dir.glob(File.expand_path('../helpers/**/*.rb', __FILE__), &method(:require))
helpers CommandReferenceHelper
helpers ConfigHelper
helpers DocsHelper
helpers AvatarHelper

activate :blog do |blog|
  blog.name = 'blog'
  blog.prefix = 'blog'
  blog.permalink = '{year}/{month}/{day}/{title}.html'
  blog.layout = 'blog_layout'

  blog.calendar_template = 'blog/calendar.html'
  blog.year_link = "{year}/index.html"
  blog.month_link = "{year}/{month}/index.html"
  blog.day_link = "{year}/{month}/{day}/index.html"
end

page "/blog/feed.xml", layout: false

configure :development do
  activate :livereload
end

configure :build do
  activate :minify_css
  activate :minify_javascript
end
