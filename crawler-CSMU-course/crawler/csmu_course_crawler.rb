require 'crawler_rocks'
require 'json'
require 'iconv'
require 'pry'

class CsmuCourseCrawler

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7
    }

  PERIODS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "午" => 5,
    "5" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "9" => 10,
    "10" => 11,
    "11" => 12,
    "12" => 13,
    "13" => 14,
    "14" => 15
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://csads.csmu.edu.tw/schedule/'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []

    r = RestClient.get(@query_url + 'ByTimeQueryX.asp')
    doc = Nokogiri::HTML(@ic.iconv(r))

    doc.css('select[name="pfx_ChDayNight"] option:nth-child(n+2)').map{|opt| opt[:value]}.each do |day_night|

      doc.css('select[name="pfx_ChClassDep"] option:nth-child(n+2)').map{|opt| opt[:value]}.each do |class_dep|

        r = RestClient.post(@query_url + 'ByTimeListX.asp', {
          "pfx_ChYear" => @year - 1911,
          "pfx_ChSeme" => @term,
          "pfx_ChDayNight" => day_night,
          "pfx_ChClassDep" => class_dep,
          "pfx_ChDeptNo1" => "",
          "pfx_ChDeptNo2" => "",
          "xxx_Dept" => "",
          "pfx_ChGrade" => "",
          "pfx_ChClassNo" => "",
          "ChTeaName" => "",
          "day1" => "",
          "day2" => "",
          "class1" => "",
          "class2" => "",
          "chsubjname" => "",
          })
        cookies = r.cookies

        r = RestClient.get(@query_url + "ByTimeListX.asp?nowPage=1&pagesize=2000", cookies: cookies)
        doc = Nokogiri::HTML(@ic.iconv(r))

        course_id = 0
        doc.css('table table tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
          data = tr.css('td').map{|td| td.text}
          data[-1] = tr.css('td a').map{|a| a[:href]}[0]
          course_id += 1

          time_period_regex = /(?<day>[一二三四五六日])\,(?<period>([\d午]+\,?)+)\;?/
          course_time = data[8].scan(time_period_regex)

          course_days, course_periods, course_locations = [], [], []
          course_time.each do |day, period|
            period.split(',').each do |p|
              course_days << DAYS[day]
              course_periods << PERIODS[p]
              course_locations << data[9]
            end
          end

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[2],    # 課程名稱
            lecturer: data[7],    # 授課教師
            credits: data[5].to_i,    # 學分數
            code: "#{@year}-#{@term}-#{course_id}-?(#{data[1]})?",
            # general_code: data[1],    # 選課代碼
            url: "#{@query_url}#{data[-1]}",    # 課程大綱之類的連結
            required: data[4].include?('必'),    # 必修或選修
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
      end
    end
# binding.pry
    @courses
  end

end

# crawler = CsmuCourseCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
