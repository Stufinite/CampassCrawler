require 'web_task_runner'

# Require the crawler
Dir[File.dirname(__FILE__) + '/crawler/*.rb'].each { |file| require file }

class CrawlWorker < WebTaskRunner::TaskWorker
  def exec
    year = (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
    term = (Time.now.month.between?(2, 7) ? 2 : 1)

    year = params[:year].to_i if params[:year]
    term = params[:term].to_i if params[:term]

    puts "Starting crawler for #{year}-#{term} ..."

    crawler = DaYehUniversityCrawler.new(
      year: year,
      term: term,
      update_progress: proc { |payload| WebTaskRunner.job_1_progress = payload[:progress] },
      after_each: proc do |payload|
        course = payload[:course]
        print "Saving course #{course[:code]} ...\n"

        RestClient.put("#{ENV['DATA_MANAGEMENT_API_ENDPOINT']}/#{course[:code]}?key=#{ENV['DATA_MANAGEMENT_API_KEY']}",
          { ENV['DATA_NAME'] => course }
        )
        print "after_each done :D"
        # WebTaskRunner.job_1_progress = payload[:progress]
      end
    )

    courses = crawler.courses()

    # TODO: delete the courses which course code not present in th list
  end
end

WebTaskRunner.jobs << CrawlWorker
