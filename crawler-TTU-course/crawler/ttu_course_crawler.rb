require 'json'
require 'pry'

require 'crawler_rocks'

require 'thread'
require 'thwait'

require_relative './ttu_code'

class TtuCourseCrawler
  include CrawlerRocks::DSL
  include TtuCode

  DAYS = [6, 5, 4, 3, 2, 1]

  PERIODS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "午" => 5,
    "五" => 6,
    "六" => 7,
    "七" => 8,
    "八" => 9,
    "晚" => 10,
    "九" => 11,
    "十" => 12,
    "十一" => 13,
    "十二" => 14
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    # Capybara.default_driver = :selenium
    # Capybara.javascript_driver = :selenium
    @query_url = "http://selquery.ttu.edu.tw/Main/ViewClass.php"

    @courses = {}
  end

  def courses
    visit @query_url

    @threads = []
    @parse_detail_threads = []
    @last_group_code = nil

    departments = Hash[@doc.css('select[name="SelDp"] option').map {|s| [s[:value], s.text]}]
    departments.keys.each_with_index do |dep_code, dep_index|
      post @query_url, get_view_state.merge({
        :SelDp => dep_code,
        # :SelCl => ,
      })
      groups = Hash[@doc.css('select[name="SelCl"] option').map {|s| [s[:value], s.text]}]
      groups.keys.each_with_index do |group_code, group_index|
        print "#{dep_code} - #{group_code}\n"

        sleep(1) until (
          @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
          @threads.count < (ENV['MAX_THREADS'] || 30)
        )
        @threads << Thread.new do
          post @query_url, get_view_state.merge({
            :SelDp => dep_code,
            :SelCl => group_code,
          })

          # File.write("deprecated/html/#{dep_code}-#{group_code}.html", html)

          table = @doc.css('table.cistab')[0]

          rows = table.css('tr:not(:first-child)')
          rows.each_with_index do |row, periods|
            grids = row.css('td')
            grids[0..-2].each_with_index do |grid, days| # skip last
              # empty precheck
              next if grid.text.power_strip.empty?

              # course urls
              urls = grid.css('a').map {|a| "http://selquery.ttu.edu.tw/Main/#{a["href"]}"}

              # replace br for splitting
              grid.search('br').each {|n| n.replace("\n")}
              classes = grid.text.split("\n")
              classes.each {|e| classes.delete(e) if e.length == 0}

              # 看起來會長這樣，三個一組
              # [
              #   "G1511M",
              #   "英文(一)",
              #   "A8-B208",
              #   "G1511N",
              #   "英文(一)",
              #   "A8-B202"
              # ]
              0.step(classes.count-1, 3) do |i|
                # initial object
                course_code = classes[i]
                c_hash = "#{@year}-#{@term}-#{course_code}-#{dep_code}-#{group_code}"
                classroom = classes[i+2]
                day = DAYS[days]
                period = PERIODS[PERIODS.keys[periods]]

                print "parsing #{c_hash}...\n"

                @courses[c_hash] = {} if @courses[c_hash].nil?
                @courses[c_hash][:code] = c_hash
                @courses[c_hash][:name] = classes[i+1]
                @courses[c_hash][:url] = urls[i/3]
                @courses[c_hash][:time] = [] if @courses[c_hash][:time].nil?
                @courses[c_hash][:department] = departments[dep_code]
                @courses[c_hash][:department_code] = dep_code
                @courses[c_hash][:class] = groups[group_code]
                @courses[c_hash][:group_code] = group_code
                @courses[c_hash][:year] = @year
                @courses[c_hash][:term] = @term


                @courses[c_hash][:time] << {
                  day: day,
                  period: period,
                  classroom: classroom
                }
                @courses[c_hash][:time].uniq!

                unless @courses[c_hash][:textbook] || @courses[c_hash][:reference]
                  sleep(1) until (
                    @parse_detail_threads.delete_if { |t| !t.status };  # remove dead (ended) threads
                    @parse_detail_threads.count < (ENV['MAX_THREADS'] || 50)
                  )
                  @parse_detail_threads << Thread.new do
                    # puts "parse_syllabus: #{course_code}"
                    parse_syllabus(course_code, c_hash)
                  end
                end # unless need to parse_syllabus

                # binding.pry
                unless @courses[c_hash][:lecturer] || @courses[c_hash][:required] || @courses[c_hash][:credits]
                  sleep(1) until (
                    @parse_detail_threads.delete_if { |t| !t.status };  # remove dead (ended) threads
                    @parse_detail_threads.count < (ENV['MAX_THREADS'] || 50)
                  )
                  @parse_detail_threads << Thread.new do
                    # puts "parse_detail: #{course_code}"
                    parse_detail(course_code, c_hash)
                  end
                end # unless parse_detail
              end # 0.step(classes.count-1, 3)
            end # grids[0..-2].each_with_index
          end # rows.each_with_index
        end # Thread do
      end # group.keys do

      print "done: #{dep_index} / #{departments.count}\n"
    end # departments.keys do

    ThreadsWait.all_waits(*@threads)
    ThreadsWait.all_waits(*@parse_detail_threads)

    # deps = JSON.parse(File.read('ttu_code.json'));

    @update_threads = []
    @courses.each do |k, course|
      sleep(1) until (
        @update_threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @update_threads.count < (ENV['MAX_THREADS'] || 30)
      )
      @update_threads << Thread.new do
        # convert code
        # deps.each do |k, v|
        #   v.reverse_each do |dep|
        #     if course["class"].include?(dep["department"])
        #       # binding.pry
        #       course["department_code"] = dep["code"]
        #       break
        #     end
        #   end
        # end

        # covert time table
        course_days = []
        course_periods = []
        course_locations = []
        course[:time].each do |time|
          course_days << time[:day]
          course_periods << time[:period]
          course_locations << time[:classroom]
        end
        course.delete(:time)

        course[:day_1] = course_days[0]
        course[:day_2] = course_days[1]
        course[:day_3] = course_days[2]
        course[:day_4] = course_days[3]
        course[:day_5] = course_days[4]
        course[:day_6] = course_days[5]
        course[:day_7] = course_days[6]
        course[:day_8] = course_days[7]
        course[:day_9] = course_days[8]
        course[:period_1] = course_periods[0]
        course[:period_2] = course_periods[1]
        course[:period_3] = course_periods[2]
        course[:period_4] = course_periods[3]
        course[:period_5] = course_periods[4]
        course[:period_6] = course_periods[5]
        course[:period_7] = course_periods[6]
        course[:period_8] = course_periods[7]
        course[:period_9] = course_periods[8]
        course[:location_1] = course_locations[0]
        course[:location_2] = course_locations[1]
        course[:location_3] = course_locations[2]
        course[:location_4] = course_locations[3]
        course[:location_5] = course_locations[4]
        course[:location_6] = course_locations[5]
        course[:location_7] = course_locations[6]
        course[:location_8] = course_locations[7]
        course[:location_9] = course_locations[8]

        @after_each_proc.call(course: course) if @after_each_proc
      end # end Thread
    end # @courses.map
    ThreadsWait.all_waits(*@update_threads)

    @courses.values
  end

  def crawl_each_syllabus
    course_codes = @courses.keys
    progressbar = ProgressBar.create(total: course_codes.count)
    course_codes.each do |code|
      parse_syllabus(code)
      progressbar.increment
    end
  end

  def parse_syllabus(course_code, c_hash)
    r = RestClient.get "http://selquery.ttu.edu.tw/Main/syllabusview.php?SbjNo=#{course_code}"
    doc = Nokogiri::HTML(r.to_s)

    _books = doc.css('table.cistab > tr:contains("教科書")')
    if not _books.empty? and not _books.css('td').empty?
      @courses[c_hash][:textbook] = _books.css('td').last.text.power_strip
    end

    _ref = doc.css('table.cistab > tr:contains("參考教材")')
    if not _ref.empty? and not _ref.css('td').empty?
      @courses[c_hash][:reference] = _ref.css('td').last.text.power_strip
    end

    print "parse_syllabus done: #{course_code}\n"
  end

  def parse_detail(course_code, c_hash)
    r = RestClient.get @courses[c_hash][:url]
    doc = Nokogiri::HTML(r.to_s)

    @courses[c_hash][:lecturer] = doc.css('tr:contains("授課教師") td span').first.text
    @courses[c_hash][:required] = !(doc.css('tr:contains("選別") td').first.text.strip == '選修')
    @courses[c_hash][:credits] = Integer doc.css('tr:contains("學分數") td').first.text.strip

    print "parse_detail done: #{course_code}\n"
  end

  private
    def current_year
      (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
    end

    def current_term
      (Time.now.month.between?(2, 7) ? 2 : 1)
    end
end

class String
  def power_strip
    self.strip.gsub(/^[ |\s]*|[ |\s]*$/,'')
  end
end

# cc = TtuCourseCrawler.new
# File.write('1041_ttu_courses.json', JSON.pretty_generate(cc.courses))
