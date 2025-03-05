require "nokogiri"
require "open-uri"

start_page_url = "https://job-boards.greenhouse.io/gitlab/"

current_page = Nokogiri::HTML(URI.open(start_page_url))

job_post_elements = current_page.search(".job-post")

jobs = job_post_elements.map do |post_element|
  link_element = post_element.at("a")
  title_element, location_element = post_element.search("p")

  {
    title: title_element.inner_text.strip,
    location: location_element.inner_text.strip,
    url: link_element["href"],
  }
end

puts jobs
