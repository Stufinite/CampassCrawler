require 'json'
require 'crawler_rocks'
require 'pry'

require 'thread'
require 'thwait'

class CycuCourseCrawler
  include CrawlerRocks::DSL

  PERIODS = {
    "A" => 1,
    "1" => 2,
    "2" => 3,
    "3" => 4,
    "4" => 5,
    "B" => 6,
    "5" => 7,
    "6" => 8,
    "7" => 9,
    "8" => 10,
    "C" => 11,
    "D" => 12,
    "E" => 13,
    "F" => 14,
    "G" => 15,
    "H" => 16
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

  end

  def courses detail: false
    @courses = []
    @threads = []

    url = "http://itouch.cycu.edu.tw/active_system/CourseQuerySystem/GetCourses.jsp?yearTerm=#{@year-1911}#{@term}"

    r = Curl.get(url).body_str.force_encoding('utf-8')
    data = r.strip
    rows = data.split('@@')

    rows[1..-1].each_with_index do |row, row_index|

      datas = row.split('|')
      unless datas[6].nil?
        department_code = datas[6][0..1]
        url = "http://cmap.cycu.edu.tw:8080/Syllabus/CoursePreview.html?yearTerm=#{@year-1911}#{@term}&opCode=#{datas[6]}"
      end
      required = datas[11].include?('必') unless datas[11].nil?

      # Flatten timetable
      course_days = []
      course_periods = []
      course_locations = []
      times = []

      course_locations << (datas[17] && (datas[17].empty? ? nil : datas[17] ) )
      course_locations << (datas[19] && (datas[19].empty? ? nil : datas[19] ) )
      course_locations << (datas[21] && (datas[21].empty? ? nil : datas[21] ) )

      times << datas[16]
      times << datas[18]
      times << datas[20]

      times.each do |tim|
        tim && tim.match(/(?<d>.)\-(?<p>.+)/) do |m|
          m[:p].split("").each do |period|
            course_days << m[:d].to_i
            course_periods << PERIODS[period]
          end
        end
      end

      lecturer_code = datas[15] && CGI.escape(datas[15]).tr('%', '')

      course = {
        # cros_inst: datas[1], # 跨部
        # cros_dep: datas[2], # 跨系
        # datas[4] # 停休與否
        # pho_code: datas[5], # 語音代碼
        year: @year,
        term: @term,
        code: "#{@year}-#{@term}-#{datas[6]}-#{lecturer_code}",
        general_code: datas[6], # 課程代碼
        # category: datas[7], # 課程類別
        department: datas[8], # 權責單位?
        department_code: department_code,
        # clas: datas[9], # 開課班級
        name: datas[10], # 課程名稱
        required: required, # 必選修
        # year: datas[12], # 全半年
        # datas[13] # ?
        credits: datas[14], # 學分
        lecturer: datas[15], # 授課教師
        # notes: datas[22], # 備註
        # department: datas[23], # 權責單位?
        # people: datas[24], # 開課人數
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
        url: url,
      }
      @courses << course
    end
    ThreadsWait.all_waits(*@threads)

    @courses.uniq!

    @threads = []
    @courses.each {|course|
      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < ( (ENV['MAX_THREADS'] && ENV['MAX_THREADS'].to_i) || 20)
      )
      @threads << Thread.new do
        @after_each_proc.call(course: course) if @after_each_proc
      end
    }
    ThreadsWait.all_waits(*@threads)

    @courses
  end

  # def batch_download_books
  #   codes = @courses.map {|c| c["code"]}
  #   codes.each do |c|
  #     puts "load #{c}"
  #     system("phantomjs spider.js #{c}")
  #   end
  # end

  # def map_book_data
  #   @courses.each do |c|
  #     filename = "book_datas/#{c[:code]}"
  #     if File.exist?(filename)
  #       textbook = JSON.parse(File.read(filename))
  #       c[:textbook] = textbook
  #     end
  #   end
  # end

  private
    def current_year
      (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
    end

    def current_term
      (Time.now.month.between?(2, 7) ? 2 : 1)
    end

end

# cc = CycuCourseCrawler.new(year: 2015, term: 1)
# File.open('1041_cycu_courses.json', 'w') {|f| f.write(JSON.pretty_generate(cc.courses))}
