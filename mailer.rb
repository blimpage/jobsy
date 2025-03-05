require "sendgrid-ruby"

class Mailer
  class SendError < StandardError; end
  class ConfigError < StandardError; end

  def send_new_jobs_notification(jobs)
    response = send_mail(
      subject: "New job listings!",
      html_content: generate_email_content(jobs),
    )

    success = response.status_code[0] == "2"

    unless success
      raise SendError, "Something went wrong while sending email. Response code: #{response.status_code}, Response body: #{response.body}"
    end
  end

  private

  def send_mail(subject:, html_content:)
    from = SendGrid::Email.new(email: notification_address)
    to = SendGrid::Email.new(email: notification_address)
    content = SendGrid::Content.new(type: "text/html", value: html_content)
    mail = SendGrid::Mail.new(from, subject, to, content)

    sendgrid_agent.client.mail._("send").post(request_body: mail.to_json)
  end

  def generate_email_content(jobs)
    header = "Hey, I found some new job listings for you!"

    jobs_markup = jobs.map do |job|
      <<~HEREDOC
        <strong>Department:</strong> #{job[:department]}<br />
        <strong>Title:</strong> #{job[:title]}<br />
        <strong>Location:</strong> #{job[:location]}<br />
        <strong>URL:</strong> <a href="#{job[:url]}">#{job[:url]}</a>
      HEREDOC
    end

    separator = "<br /><br />--<br /><br />"
    footer = "Okay bye!<br />https://morph.io/blimpage/jobsy"

    [header, jobs_markup.join(separator), footer].join(separator)
  end

  def sendgrid_agent
    @sendgrid_agent ||= SendGrid::API.new(api_key: sendgrid_api_key)
  end

  def notification_address
    @notification_address ||= fetch_env_variable("MORPH_NOTIFICATION_EMAIL_ADDRESS")
  end

  def sendgrid_api_key
    @sendgrid_api_key ||= fetch_env_variable("MORPH_SENDGRID_API_KEY")
  end

  def fetch_env_variable(variable_name)
    raise ConfigError, "Environment variable #{variable_name} is not set" unless ENV.key?(variable_name)

    ENV[variable_name]
  end
end
