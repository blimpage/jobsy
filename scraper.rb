require "nokogiri"
require "open-uri"

START_PAGE_NUMBER = 1

def url_for_page(page_number)
  "https://job-boards.greenhouse.io/gitlab/?page=#{page_number}"
end

current_page_number = START_PAGE_NUMBER
last_page_reached = false
jobs = []

until last_page_reached do
  current_page_url = url_for_page(current_page_number)
  current_page = Nokogiri::HTML(URI.open(current_page_url))

  job_post_elements = current_page.search(".job-post")

  if job_post_elements.none?
    last_page_reached = true
    next
  end

  current_page_jobs = job_post_elements.map do |post_element|
    link_element = post_element.at("a")
    title_element, location_element = post_element.search("p")

    {
      title: title_element.inner_text.strip,
      location: location_element.inner_text.strip,
      url: link_element["href"],
      page: current_page_number,
    }
  end

  jobs += current_page_jobs
  current_page_number += 1
end

puts jobs
