require 'crawler_rocks'
require 'iconv'
require 'json'
require 'pry'

require 'thread'
require 'thwait'

class NtutCourseCrawler
  include CrawlerRocks::DSL

  DAYS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "5" => 5,
    "6" => 6,
    "7" => 7,
    "8" => 8,
    "9" => 9,
    "A" => 10,
    "B" => 11,
    "C" => 12,
    "D" => 13,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://aps.ntut.edu.tw/course/tw/QueryCurrPage.jsp"
    @result_url = "http://aps.ntut.edu.tw/course/tw/QueryCourse.jsp"
    @base_url = "http://aps.ntut.edu.tw/course/tw/"

    @ic = Iconv.new("utf-8//translit//IGNORE", "big5")
  end

  def courses
    @courses = []
    @threads = []

    visit @query_url

    deps_h = Hash[@doc.css('select[name="unit"] option:not(:first-child)').map{|opt| [opt[:value], opt.text]}]

    deps_h.each do |dep_c, dep_n|
      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < (ENV['MAX_THREADS'] || 10)
      )
      @threads << Thread.new do

        update_threads = []

        r = RestClient.post @result_url, {
          "stime" => 0,
          "year" => @year-1911,
          "sem" => @term,
          "matric" => "'0','1','4','5','6','7','8','9','A','C','D','E','F'",
          "cname" => ' ',
          "ccode" => nil,
          "tname" => nil,
          "unit" => dep_c,
          "D0" => "ON", "D1" => "ON", "D2" => "ON", "D3" => "ON", "D4" => "ON", "D5" => "ON", "D6" => "ON", "P1" => "ON", "P2" => "ON", "P3" => "ON", "P4" => "ON", "P5" => "ON", "P6" => "ON", "P7" => "ON", "P8" => "ON", "P9" => "ON", "P10" => "ON", "P11" => "ON", "P12" => "ON", "P13" => "ON",
          "search" => CGI.escape('開始查詢'.encode('big5')),
        }, cookies: @cookies

        doc = Nokogiri::HTML(@ic.iconv(r))
        doc.css('table tr:not(:first-child)').each do |row|
          datas = row.css('td')

          course_days = []
          course_periods = []
          course_locations = []
          loc = datas[15].text.strip
          datas[8..14].each_with_index do |d, i|
            d.text.gsub(/[^A-Z\d]/,'').split('').each do |p|
              # i:   0 1 2 3 4 5 6
              # day: 7 1 2 3 4 5 6
              i = 7 if i == 0
              course_days << i
              course_periods << DAYS[p]
              course_locations << loc
            end
          end

          # 看起來像是所有的 serial
          serial_no = datas[0] && datas[0].text.strip
          required_raw = datas[5] && datas[5].text.strip
          required = required_raw != '☆' && required_raw != '★'
          url = datas[1] && !datas[1].css('a').empty? && "#{@base_url}#{datas[1].css('a')[0][:href]}"
          code = CGI.parse(URI(url).query)["code"][0]

          course = {
            year: @year,
            term: @term,
            code: "#{@year}-#{@term}-#{code}",
            name: datas[1] && datas[1].text.strip,
            department: datas[6] && datas[6].text.split("\n"),
            course_department: dep_n,
            department_code: dep_c,
            # stage: datas[2] && datas[2].text.strip,
            credits: datas[3] && datas[3].text.to_i,
            # hours: datas[4] && datas[4].text.to_i,
            required: required,
            lecturer: datas[7] && datas[7].text.strip.tr("\n", ',').tr("　", ''),
            url: datas[1] && !datas[1].css('a').empty? && "#{@base_url}#{datas[1].css('a')[0][:href]}",
            day_1: course_days[0],
            day_2: course_days[1],
            day_3: course_days[2],
            day_4: course_days[3],
            day_5: course_days[4],
            day_6: course_days[5],
            day_7: course_days[6],
            day_8: course_days[7],
            day_9: course_days[8],
            period_1: course_periods[0],
            period_2: course_periods[1],
            period_3: course_periods[2],
            period_4: course_periods[3],
            period_5: course_periods[4],
            period_6: course_periods[5],
            period_7: course_periods[6],
            period_8: course_periods[7],
            period_9: course_periods[8],
            location_1: course_locations[0],
            location_2: course_locations[1],
            location_3: course_locations[2],
            location_4: course_locations[3],
            location_5: course_locations[4],
            location_6: course_locations[5],
            location_7: course_locations[6],
            location_8: course_locations[7],
            location_9: course_locations[8],
          }
          sleep(1) until (
            update_threads.delete_if { |t| !t.status };  # remove dead (ended) threads
            update_threads.count < (ENV['MAX_THREADS'] || 25)
          )
          update_threads << Thread.new do
            @after_each_proc.call(course: course) if @after_each_proc
          end
          @courses << course
        end
        ThreadsWait.all_waits(*update_threads)
        print "#{dep_n}\n"
      end # end new theads
    end # end each deps
    ThreadsWait.all_waits(*@threads)

    expanded_courses = []
    @courses.each do |course|
      expanded_courses.concat(course[:department].map{|dep|
        course[:department] = dep
        course
      })
    end

    @courses
  end # end courses method

  def current_year
    (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
  end

  def current_term
    (Time.now.month.between?(2, 7) ? 2 : 1)
  end
end

# cc = NtutCourseCrawler.new(year: 2014, term: 1)
# File.write('1031courses.json', JSON.pretty_generate(cc.courses))
