require 'crawler_rocks'
require 'json'
require 'pry'

require 'thread'
require 'thwait'

class CguCourseCrawler
  include CrawlerRocks::DSL

  DAYS = {
    "Mon" => 1,
    "Tue" => 2,
    "Wed" => 3,
    "Thu" => 4,
    "Fri" => 5,
    "Sat" => 6,
    "Sun" => 7,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @base_url = "http://www.is.cgu.edu.tw/portal/"
    @query_url = "http://www.is.cgu.edu.tw/portal/DesktopDefault.aspx?tabindex=1&tabid=61"

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each
  end

  def courses
    @courses_h = {}
    @threads = []

    visit @query_url

    dept_h = Hash[@doc.css('select[name="_ctl1:departmentsList"] option:not(:first-child)').map{|opt| [opt[:value], opt.text.split(' ')[0]]}]
    dept_rev = Hash[dept_h.map{|k, v| [v, k]}]

    sem_h = Hash[@doc.css('select[name="_ctl1:termsList"] option').map{|opt| [opt[:value], opt.text]}]
    # {"39"=>"103 / 1"}
    sem = sem_h.find{|arr| arr[1].match(/(#{@year-1911})\ \/\ (#{@term})/)}[0]

    if not sem
      print "Year and Semester not Found! Byebye~\n"
      return
    end

    form_url = "#{@base_url}#{@doc.css('form')[0][:action]}"
    RestClient.post(form_url, get_view_state.merge({
      "_ctl1:termsList" => sem,
      "_ctl1:departmentsList" => -1,
      "_ctl1:newSearch" => @doc.css('input[name="_ctl1:newSearch"]')[0][:value],
      "_ctl1:callID" => nil,
      "_ctl1:courseID" => nil,
      "_ctl1:InstructorName" => nil,
      "_ctl1:courseName" => ' ',
      "_ctl1:weekDay" => -1,
      "_ctl1:beginSection" => -1,
      "_ctl1:endSection" => -1,
      "_ctl1:classID" => -1,
      "_ctl1:fieldsList" => -1,
    }), cookies: @cookies) do |response, request, result, &block|
      if [301, 302, 307].include? response.code
        @redirected_url = response.headers[:location]
      else
        response.return!(request, result, &block)
      end
    end

    visit @redirected_url

    @doc.css('#_ctl2_myGrid tr:not(:first-child)').each do |row|
      datas = row.css('td')

      serial_no = datas[2] && datas[2].text.strip
      general_code = datas[1] && datas[1].text.strip
      code = "#{@year}-#{@term}-#{general_code}-#{serial_no}"

      datas[5].search('br').each {|br| br.replace("\n")}
      name = datas[5].text.strip.split("\n")[0]

      url = datas[5].css('a')[0][:href].prepend(@base_url)
      department = datas[3] && datas[3].text.strip
      department_code = dept_rev[department]

      @courses_h[code] = {
        year: @year,
        term: @term,
        code: code,
        general_code: general_code,
        department: department,
        department_code: department_code,
        grade: datas[4] && datas[4].text.to_i,
        name: name,
        url: url,
        lecturer: datas[6] && datas[6].text.strip,
        credits: datas[7] && datas[7].text.to_i,
      }

    end # end each row

    # parse detail
    parse_time_location
    ThreadsWait.all_waits(*@threads)

    @courses_h.values
  end # end courses method

  def parse_time_location
    @courses_h.each do |code, course|
      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < ( (ENV['MAX_THREADS'] && ENV['MAX_THREADS'].to_i) || 30)
      )

      @threads << Thread.new do
        r = RestClient.get course[:url]
        doc = Nokogiri::HTML(r)

        course_days = []
        course_periods = []
        course_locations = []
        doc.css('#CourseDetail1_sectionTimeGrid tr:not(:first-child)').each do |row|
          datas = row.css('td')
          m_day = datas[0].text.match(/#{DAYS.keys.join('|')}/)
          day = m_day && DAYS[m_day[0]] || nil

          loc = datas[2].text.strip
          datas[1].text.gsub(/\s|\u00A0/, '').match(/(?<beg_p>\d)\((\d{2}\:\d{2})\)\~(?<end_p>\d)\((\d{2}\:\d{2})\)/) do |m|
            (m[:beg_p].to_i..m[:end_p].to_i).each do |p|
              course_days << day
              course_periods << p
              course_locations << loc
            end
          end

          if day.nil?
            course_days = []
            course_periods = []
            course_locations = []
          end

          @courses_h[code][:day_1] = course_days[0]
          @courses_h[code][:day_2] = course_days[1]
          @courses_h[code][:day_3] = course_days[2]
          @courses_h[code][:day_4] = course_days[3]
          @courses_h[code][:day_5] = course_days[4]
          @courses_h[code][:day_6] = course_days[5]
          @courses_h[code][:day_7] = course_days[6]
          @courses_h[code][:day_8] = course_days[7]
          @courses_h[code][:day_9] = course_days[8]
          @courses_h[code][:period_1] = course_periods[0]
          @courses_h[code][:period_2] = course_periods[1]
          @courses_h[code][:period_3] = course_periods[2]
          @courses_h[code][:period_4] = course_periods[3]
          @courses_h[code][:period_5] = course_periods[4]
          @courses_h[code][:period_6] = course_periods[5]
          @courses_h[code][:period_7] = course_periods[6]
          @courses_h[code][:period_8] = course_periods[7]
          @courses_h[code][:period_9] = course_periods[8]
          @courses_h[code][:location_1] = course_locations[0]
          @courses_h[code][:location_2] = course_locations[1]
          @courses_h[code][:location_3] = course_locations[2]
          @courses_h[code][:location_4] = course_locations[3]
          @courses_h[code][:location_5] = course_locations[4]
          @courses_h[code][:location_6] = course_locations[5]
          @courses_h[code][:location_7] = course_locations[6]
          @courses_h[code][:location_8] = course_locations[7]
          @courses_h[code][:location_9] = course_locations[8]

          @after_each_proc.call(course: @courses_h[code]) if @after_each_proc
        end  # each row do
      end # Thead.new do
    end# @courses_h.each do
  end # end parse_time_location

  def current_year
    (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
  end

  def current_term
    (Time.now.month.between?(2, 7) ? 2 : 1)
  end
end # end class

# cc = CguCourseCrawler.new(year: 2014, term: 1)
# File.write('cgu_courses.json', JSON.pretty_generate(cc.courses))
