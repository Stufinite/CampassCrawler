require 'crawler_rocks'
require 'json'
require 'pry'

class NationalQuemoyUniversityCrawler

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each


    @query_url = 'http://select1.nqu.edu.tw/kmkuas/perchk.jsp'
  end

  def courses
    @courses = []

    r = RestClient.post(@query_url, {
      "uid" => "guest",
      "pwd" => "123",
      })
    cookie = "JSESSIONID=#{r.cookies["JSESSIONID"]}"

    @query_url = "http://select1.nqu.edu.tw/kmkuas/ag_pro/ag304_01.jsp"
    r = RestClient.get(@query_url, {"Cookie" => cookie })
    doc = Nokogiri::HTML(r)

    dep = Hash[doc.css('select[name="unit_id"] option').map{|opt| [opt[:value],opt.text]}]
    dep.each do |dep_c, dep_n|

      @query_url = "http://select1.nqu.edu.tw/kmkuas/ag_pro/ag304_02.jsp"
      r = RestClient.post(@query_url, {
        "yms_year" => @year - 1911,
        "yms_sms" => @term,
        "unit_id" => dep_c,
        "unit_serch" => "%E6%9F%A5+%E8%A9%A2",
        }, {"Cookie" => cookie })
      doc = Nokogiri::HTML(r)

      degree = Hash[doc.css('table tr:not(:first-child) td[style="font-size: 9pt;color:blue;"] div').map{|td| [td[:onclick].split('\'')[1], td.text]}]
      degree.each do |degree_c, degree_n|

        @query_url = "http://select1.nqu.edu.tw/kmkuas/ag_pro/ag304_03.jsp"
        r = RestClient.post(@query_url, {
          "arg01" => @year - 1911,
          "arg02" => @term,
          "arg" => degree_c,
          }, {"Cookie" => cookie })
        doc = Nokogiri::HTML(r)

        next if doc.css('table')[0] == nil
        doc.css('table')[0].css('tr:not(:first-child)').map{|tr| tr}.each do |tr|
          data = tr.css('td').map{|td| td.text}

          time_period_regex = /\((?<day>[一二三四五六日])\)(?<period>(\d-?\d?,?)+)/
          course_time = Hash[ data[7].scan(time_period_regex) ]

          course_days, course_periods, course_locations = [], [], []
          course_time.each do |k, v|
            v.split(',').each do |period_temp|
              (period_temp.split('-')[0].to_i..period_temp.split('-')[-1].to_i).each do |period|
                period += 9 if degree_n.include?('進') && k != "六" && k != "日"
                course_days << DAYS[k]
                course_periods << period
                course_locations << data[9]
              end
            end
          end

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[1],    # 課程名稱
            lecturer: data[8],    # 授課教師
            credits: data[3].to_i,    # 學分數
            code: "#{@year}-#{@term}-#{dep_c}-?(#{data[0].scan(/\w+/)[0]})?",
            # general_code: data[0],    # 選課代碼
            required: data[5].include?('必'),    # 必修或選修
            department: dep_n,    # 開課系所
            # department_code: dep_c,
            # note: data[10],
            # group: data[2],
            # hours: data[4],
            # department_term: data[6],
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

# crawler = NationalQuemoyUniversityCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
