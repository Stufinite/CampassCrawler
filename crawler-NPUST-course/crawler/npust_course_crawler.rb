require 'crawler_rocks'
require 'json'
require 'pry'

class NpustCourseCrawler

  PERIODS = {
    "0" => 1,
    "1" => 2,
    "2" => 3,
    "3" => 4,
    "4" => 5,
    "C" => 6,
    "5" => 7,
    "6" => 8,
    "7" => 9,
    "8" => 10,
    "9" => 11,
    "10" => 12,
    "11" => 13,
    "12" => 14,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://course.npust.edu.tw/Cnc/'
  end

  def courses
    @courses = []

    cookies = RestClient.get("#{@query_url}Reports/QueryCourseforStud.aspx", :param => p) do |response, request, result, &block|
      if [301, 302, 307].include? response.code
        redirected_url = response.cookies
      else
        response.return!(request, result, &block)
      end
    end

    r = RestClient.get("#{@query_url}Reports/QueryCourseforStud.aspx", cookies: cookies)
    doc = Nokogiri::HTML(r)

    check = []
    doc.css('select[name="ctl00$MainContent$DropDownListDept"] option:nth-child(n+2)').map{|opt| [opt[:value], opt.text]}.each do |dept_c, dept_n|
      next if check.include?(dept_c)
      check << dept_c
      courses_temp = []

      r = RestClient.get("#{@query_url}Reports/QueryCourseforStud.aspx", cookies: cookies)
      doc = Nokogiri::HTML(r)

      doc = Nokogiri::HTML(post(doc, dept_c, cookies))

      courses_temp += doc.css('table tr[onmouseover="c=this.style.backgroundColor;this.style.backgroundColor=\'#00A9FF\'"]').map{|tr| tr.css('td').map{|td| td.text}}

      next if doc.css('table tr td[colspan="21"] td') == nil
      (2..doc.css('table tr td[colspan="21"] td').count).each do |page|
        doc = Nokogiri::HTML(post(doc, dept_c, cookies, eventtarget: "ctl00$MainContent$GridView1", eventargument: "Page$#{page}", x: nil, y: nil))

        courses_temp += doc.css('table tr[onmouseover="c=this.style.backgroundColor;this.style.backgroundColor=\'#00A9FF\'"]').map{|tr| tr.css('td').map{|td| td.text}}
      end
      course_temp(courses_temp)
    end

# binding.pry
    @courses
  end

  def post(doc, dept_c, cookies, eventtarget: nil, eventargument: nil, x: "10", y: "10")
    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = RestClient.post(@query_url + "Reports/QueryCourseforStud.aspx", hidden.merge({
      "__EVENTTARGET" => eventtarget,
      "__EVENTARGUMENT" => eventargument,
      "__LASTFOCUS" => "",
      "ctl00$MainContent$DropDownListAca" => @year - 1911,
      "ctl00$MainContent$DropDownListTerm" => @term,
      "ctl00$MainContent$DropDownListDayOrNight" => "%",
      "ctl00$MainContent$TextBox_fseq" => "",
      "ctl00$MainContent$ImgSure.x" => x,
      "ctl00$MainContent$ImgSure.y" => y,
      "ctl00$MainContent$DropDownListCourLab" => "0",
      "ctl00$MainContent$DropDownListOutside" => "0",
      "ctl00$MainContent$TextBoxCourse" => "",
      "ctl00$MainContent$DropDownListGroupID" => "",
      "ctl00$MainContent$ChkDept" => "on",
      "ctl00$MainContent$DropDownListDept" => dept_c,
      "ctl00$MainContent$DropDownList_icdf" => "0",
      "ctl00$MainContent$TextBoxTeacheName" => "",
      "ctl00$MainContent$DropDownList_mix" => "0",
      "ctl00$MainContent$DropDownList_NetWork" => "1",
      "ctl00$MainContent$DropDownList_English" => "1",
      "ctl00$MainContent$DropDownList_Week" => "",
      "ctl00$MainContent$DropDownList_ClassTime" => "",
      "ctl00$MainContent$RoomTextBox" => "",
      "ctl00$MainContent$DropDownListRoom" => "AG 102",
      }), cookies: cookies )
  end

  def course_temp(courses_temp)
    data_temp = []
    course_days, course_periods, course_locations, course_check = [], [], [], []
    (0..courses_temp.count - 1).each do |i|

      data = courses_temp[i]

      if not course_check.include?("#{data[13]}#{data[14]}")
        course_days << data[13].to_i
        course_periods << PERIODS[data[14]]
        course_locations << data[15]
        course_check << "#{data[13]}#{data[14]}"
      end

      if courses_temp[i+1] != nil
        a = courses_temp[i][1] == courses_temp[i+1][1]
      else
        a = false
      end
      if a
        if data_temp == []
          data_temp = data
        end
      else
        if data_temp != []
          data = data_temp
          data_temp = []
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[5],    # 課程名稱
          lecturer: data[3],    # 授課教師
          credits: data[11].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{data[4]}-?(#{data[1]})?",
          # general_code: data[1],    # 選課代碼
          department: "#{data[0]}#{data[8]}",    # 開課系所
          # department_code: dept_c,
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

        course_days, course_periods, course_locations, course_check = [], [], [], []
      end
    end
  end
end

# crawler = NpustCourseCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
