require "nokogiri"
require "open-uri"
require_relative "database"
require_relative "mailer"

START_PAGE_NUMBER = 1

def url_for_page(page_number)
  "https://job-boards.greenhouse.io/gitlab/?departments%5B%5D=4011044002&page=#{page_number}"
end

database = Database.new
mailer = Mailer.new

current_page_number = START_PAGE_NUMBER
last_page_reached = false
jobs = []

until last_page_reached do
  puts "Scraping page #{current_page_number} for job listings..."

  current_page_url = url_for_page(current_page_number)
  current_page = Nokogiri::HTML(URI.open(current_page_url))

  job_post_elements = current_page.search(".job-post")

  if job_post_elements.none?
    puts "  No jobs found. We've got em all!"
    last_page_reached = true
    next
  end

  current_page_jobs = job_post_elements.map do |post_element|
    department_element = post_element.ancestors(".job-posts--table").first.previous_sibling
    link_element = post_element.at("a")
    title_element, location_element = post_element.search("p")

    title_element.at(".tag-container")&.remove # Delete "NEW" tag if present, so that "NEW" doesn't end up in the title

    {
      department: department_element.inner_text.strip,
      title: title_element.inner_text.strip,
      location: location_element.inner_text.strip,
      url: link_element["href"],
    }
  end

  puts "  #{current_page_jobs.count} job(s) found."

  jobs += current_page_jobs
  current_page_number += 1
end

puts "\n#{jobs.count} total job(s) found. Checking which ones are new..."

persisted_job_urls = database.persisted_job_urls

new_jobs = jobs.reject do |potentially_new_job|
  persisted_job_urls.include?(potentially_new_job[:url])
end

if new_jobs.any?
  puts "  #{new_jobs.count} new job(s) found!"

  puts "Sending notification email..."
  mailer.send_new_jobs_notification(new_jobs)
  puts "  Sent!"

  puts "Saving new results to the database..."
  database.persist_jobs(new_jobs)
  puts "  Saved!"

  puts "\nAll done! Bye!"
else
  puts "  No new jobs found. Oh well, maybe tomorrow. Seeya then."
end
