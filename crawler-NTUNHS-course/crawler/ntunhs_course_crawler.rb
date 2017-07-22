require 'crawler_rocks'
require 'json'
require 'pry'
require 'httpclient'

class NtunhsCourseCrawler

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://system10.ntunhs.edu.tw/AcadInfoSystem/Modules/QueryCourse/QueryCourse.aspx'
  end

  def courses
    @courses = []

    r = HTTPClient.get(@query_url).body
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = HTTPClient.post(@query_url, hidden.merge({
      "ctl00$ScriptManager1" => "ctl00$ScriptManager1|ctl00$ContentPlaceHolder1$btnQuery",
      "__EVENTTARGET" => "",
      "__EVENTARGUMENT" => "",
      "ctl00$ContentPlaceHolder1$ddlSem" => "#{@year - 1911}#{@term}",
      "ctl00$ContentPlaceHolder1$ddlDept" => "",
      "ctl00$ContentPlaceHolder1$ddlProgram" => "",
      "ctl00$ContentPlaceHolder1$ddlDeptProgram" => "",
      "ctl00$ContentPlaceHolder1$hidDeptProgram" => "",
      "ctl00$ContentPlaceHolder1$txtTeachNo" => "",
      "ctl00$ContentPlaceHolder1$txtTeachName" => "",
      "ctl00$ContentPlaceHolder1$txtCourseNo" => "",
      "ctl00$ContentPlaceHolder1$txtCourseName" => "",
      "ctl00$ContentPlaceHolder1$txtClassNo" => "",
      "ctl00$ContentPlaceHolder1$txtClassName" => "",
      "ctl00$ContentPlaceHolder1$txtRoomNo" => "",
      "ctl00$ContentPlaceHolder1$ddlCompare" => "",
      "ctl00$ContentPlaceHolder1$txtCNT" => "",
      "ctl00$ContentPlaceHolder1$hidSelectItem" => "",
      "ctl00$ContentPlaceHolder1$hidEmptyFlag" => "false",
      "ctl00$ContentPlaceHolder1$hidEmptyDataText" => "查無符合條件資料",
      "__ASYNCPOST" => "true",
      "ctl00$ContentPlaceHolder1$btnQuery" => "查詢",
      }), {"User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/44.0.2403.89 Chrome/44.0.2403.89 Safari/537.36"}).body
    doc = Nokogiri::HTML(r)

    data_temp = []
    course_days, course_periods, course_locations = [], [], []

    (0..doc.css('table tr:nth(n+2)').count - 1).each do |tr|
      data = doc.css('table tr:nth(n+2)')[tr].css('td span').map{|td| td.text}
      data[-1] = doc.css('table tr:nth(n+2)')[tr].css('td span').map{|td| td[:title]}[3]

      if data.count < 6
        if data[0].length > 1
          data[14], data[15] = data[1], data[2]
        else
          data[14], data[15] = data[0], data[1]
        end
      elsif data.count < 10
        data[13], data[14], data[15] = data[3], data[4], data[5]
      end

      data[15].scan(/(?<period>(\d+\~?\,?)+)/).each do |period|
        (0..period[0].split(',').count - 1).each do |i|
          (period[0].split(',')[i].split('~')[0].to_i..period[0].split(',')[i].split('~')[-1].to_i).each do |p|
            course_days << data[14].to_i
            course_periods << p
            course_locations << data[13]
          end
        end
      end

      if doc.css('table tr:nth(n+2)').map{|tr| tr[:group]}[tr] == doc.css('table tr:nth(n+2)').map{|tr| tr[:group]}[tr+1] && data_temp == []
        data_temp = data
      elsif doc.css('table tr:nth(n+2)').map{|tr| tr[:group]}[tr] != doc.css('table tr:nth(n+2)').map{|tr| tr[:group]}[tr+1]
        if data_temp != []
          data = data_temp
          data_temp = []
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[3],    # 課程名稱
          lecturer: data[7],    # 授課教師
          credits: data[11].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{data[0]}-?(#{data[-1]})?",
          # general_code: data[-1],    # 選課代碼
          required: data[12].include?('必'),    # 必修或選修
          department: "#{data[1]} #{data[2]}",    # 開課系所
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
        course_days, course_periods, course_locations = [], [], []

        @after_each_proc.call(course: course) if @after_each_proc

        @courses << course
      end
    end

# binding.pry if data[0] == "0814"
    @courses
  end

end

# crawler = NtunhsCourseCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
