require 'crawler_rocks'
require 'json'
require 'pry'

class NanhuaUniversityCrawler

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7,
    }

  PERIODS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "5" => 5,
    "6" => 6,
    "7" => 7,
    "8" => 8,
    "9" => 9,
    "10" => 10,
    "11" => 11,
    "12" => 12,
    "13" => 13,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year-1911
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://203.72.2.6/acad2008NET4/QrySemCourses.aspx'
  end

  def courses
    @courses = []

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    doc = Nokogiri::HTML(post(hidden))

    Hash[doc.css('select[id="CmbCollege"] option:nth-child(n+2)').map{|opt| [opt[:value], opt.text]}].each do |col_c, col_n|

      hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

      doc = Nokogiri::HTML(post(hidden, col: col_c))

      Hash[doc.css('select[id="CmbUnit"] option:nth-child(n+2)').map{|opt| [opt[:value], opt.text]}].each do |dep_c, dep_n|

        hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

        doc = Nokogiri::HTML(post(hidden, col: col_c, cmbUnit: "CmbUnit", unit: dep_c))

        doc.css('table[id="DataGrid"] tr:not(:first-child):not(:last-child)').map{|tr| tr}.each do |tr|
          next if doc.css('table[id="DataGrid"] tr:not(:first-child):not(:last-child)') == nil

          data = tr.css('td').map{|td| td.text}
          syllabus_url = tr.css('td a').map{|a| a[:href]}[0]

          time_period_regex = /\[(?<day_peri>[一二三四五六日]\d+)\-(?<loc>\w+)/
          course_time_location = Hash[ data[9].scan(time_period_regex).map{|a| a} ]

          # 把 course_time_location 轉成資料庫可以儲存的格式
          course_days = []
          course_periods = []
          course_locations = []
          course_time_location.each do |k, v|
            course_days << DAYS[k[0]]
            course_periods << PERIODS[k[1..-1]]
            course_locations << v
          end

          course = {
            year: @year + 1911,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[2],    # 課程名稱
            lecturer: data[5],    # 授課教師
            credits: data[7],    # 學分數
            code: "#{@year + 1911}-#{@term}-#{data[1].scan(/\d+/)[0]}-?(#{data[0]})?",
            # general_code: old_course.cos_code,    # 選課代碼
            url: syllabus_url,    # 課程大綱之類的連結
            required: data[6].include?('必'),    # 必修或選修
            department: dep_n,    # 開課系所
            # department_code: dep_c,
            # note: data[11], data[14],    # data[11]是開課對象, [14]是備註
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

          @after_each_proc.call(course: course) if @after_each_proc

          @courses << course
        end
  # binding.pry if dep_c == '1100'
      end
    end
    @courses
  end

  def post(hidden, col: nil, cmbUnit: nil, unit: nil)
    r = RestClient.post(@query_url, hidden.merge({
      # "__EVENTTARGET" => "CmbYSemester",
      # "__EVENTARGUMENT" => "",
      # "__LASTFOCUS" => "",
      "CmbYSemester" => "#{@year}#{@term}",
      "CmbCollege" => col,
      cmbUnit => unit,
      }) )
  end
end

# crawler = NanhuaUniversityCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
