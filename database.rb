require "sqlite3"

class Database
  def persisted_job_urls
    db.query("select * from data").map do |persisted_job|
      persisted_job["url"]
    end
  rescue SQLite3::SQLException
    # The table doesn't exist yet. That's fine, just return an empty set.
    []
  end

  def persist_jobs(jobs)
    create_table

    jobs.each do |job|
      db.execute(
        "insert into data (department, title, location, url) values (?, ?, ?, ?)",
        [job[:department], job[:title], job[:location], job[:url]],
      )
    end
  end

  private

  def db
    @db ||= SQLite3::Database.new("data.sqlite", results_as_hash: true)
  end

  def create_table
    return if table_exists?

    db.execute <<-SQL
      create table data (
        department text,
        title text,
        location text,
        url text
      );
    SQL
  end

  def table_exists?
    db.table_info("data").any?
  end
end
