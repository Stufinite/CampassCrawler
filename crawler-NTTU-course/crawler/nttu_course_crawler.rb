require 'crawler_rocks'
require 'json'
require 'pry'

class NationalTaiTungUniversityCrawler

# 上課時間第1節為08:10~09:00、第6節為13:10~14:00，依此類推。

  PERIODS = {
    # "0" => 上課時間另外與老師確認
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
    "E" => 14,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "https://infosys.nttu.edu.tw/n_CourseBase_Select/"
  end

  def courses
    @courses = []

    for day_night in 1..3  # 日間部、進修部、學分班
      r = RestClient.get(@query_url + "CourseListPublic.aspx")
      doc = Nokogiri::HTML(r)

      hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

      # dep = Hash[doc.css('select[name="DropDownList2"] option:nth-child(n+3)').map{|opt| [opt[:value], opt.text]}]
      # dep.each do |dep_c, dep_n|

      r = post(hidden["__VIEWSTATE"], hidden["__EVENTVALIDATION"], day_night: day_night)
      doc = Nokogiri::HTML(r)

      course_temp(doc)

      next if doc.css('table[class="NTTU_GridView"] tr[class="NTTU_GridView_Pager"] td td') == []

      if doc.css('table[class="NTTU_GridView"] tr[class="NTTU_GridView_Pager"] td td')[1] != nil
        hidden = Hash[r.split('hiddenField')[1..-1].map{|hidden| [hidden.split('|')[1], hidden.split('|')[2]]}]

        r = post(hidden["__VIEWSTATE"], hidden["__EVENTVALIDATION"], toolkitScriptManager1: "UpdatePanel2|GridView1", day_night: day_night, __EVENTTARGET: "GridView1", __EVENTARGUMENT: "Page$2", button3_n: nil, button3_c: nil)
        doc = Nokogiri::HTML(r)

        course_temp(doc)
      end

      if not doc.css('table[class="NTTU_GridView"] tr[class="NTTU_GridView_Pager"] td td')[-1] == nil
        while doc.css('table[class="NTTU_GridView"] tr[class="NTTU_GridView_Pager"] td td')[-1].text == "..."
          for page in doc.css('table[class="NTTU_GridView"] tr[class="NTTU_GridView_Pager"] td td')[2].text.to_i..doc.css('table[class="NTTU_GridView"] tr[class="NTTU_GridView_Pager"] td td')[-2].text.to_i + 1
            hidden = Hash[r.split('hiddenField')[1..-1].map{|hidden| [hidden.split('|')[1], hidden.split('|')[2]]}]

            r = post(hidden["__VIEWSTATE"], hidden["__EVENTVALIDATION"], toolkitScriptManager1: "UpdatePanel2|GridView1", day_night: day_night, __EVENTTARGET: "GridView1", __EVENTARGUMENT: "Page$#{page}", button3_n: nil, button3_c: nil)
            doc = Nokogiri::HTML(r)

            course_temp(doc)
          end
        end
      end

      if not doc.css('table[class="NTTU_GridView"] tr[class="NTTU_GridView_Pager"] td td')[2] == nil
        if page != nil
          page_check = page
        else
          page_check = 2
        end
        for page in doc.css('table[class="NTTU_GridView"] tr[class="NTTU_GridView_Pager"] td td')[2].text.to_i..doc.css('table[class="NTTU_GridView"] tr[class="NTTU_GridView_Pager"] td td')[-2].text.to_i + 1
          next if page <= page_check
          hidden = Hash[r.split('hiddenField')[1..-1].map{|hidden| [hidden.split('|')[1], hidden.split('|')[2]]}]

          r = post(hidden["__VIEWSTATE"], hidden["__EVENTVALIDATION"], toolkitScriptManager1: "UpdatePanel2|GridView1", day_night: day_night, __EVENTTARGET: "GridView1", __EVENTARGUMENT: "Page$#{page}", button3_n: nil, button3_c: nil)
          doc = Nokogiri::HTML(r)

          course_temp(doc)
        end
      end
     # end
    end
   # binding.pry if data[3] == "CTE91H00D001"
    @courses
  end

  def post(__VIEWSTATE, __EVENTVALIDATION, toolkitScriptManager1: "UpdatePanel1|Button3", day_night: 1, dropDownList2: "%", __EVENTTARGET: nil, __EVENTARGUMENT: nil, button3_n: "Button3", button3_c: "查詢")
    r = RestClient.post(@query_url + "CourseListPublic.aspx", {
      "ToolkitScriptManager1" => toolkitScriptManager1,
      "DropDownList1" => "#{@year - 1911}#{@term}",
      "DropDownList6" => day_night,
      "DropDownList2" => dropDownList2,
      "DropDownList3" => "%",
      "DropDownList4" => "%",
      "DropDownList5" => "%",
      "DropDownList7" => "%",
      "DropDownList8" => "%",
      "TextBox6" => "0",
      "TextBox7" => "14",
      "__EVENTTARGET" => __EVENTTARGET,
      "__EVENTARGUMENT" => __EVENTARGUMENT,
      "__VIEWSTATE" => __VIEWSTATE,
      "__VIEWSTATEGENERATOR" => "5D156DDA",
      "__SCROLLPOSITIONX" => "0",
      "__SCROLLPOSITIONY" => "0",
      "__EVENTVALIDATION" => __EVENTVALIDATION,
      "__VIEWSTATEENCRYPTED" => "",
      "__ASYNCPOST" => "true",
      "#{button3_n}" => "#{button3_c}",
      }, {
        "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/43.0.2357.130 Chrome/43.0.2357.130 Safari/537.36"
        })
    end

  def course_temp(doc)
    doc.css('table[class="NTTU_GridView"] tr[class="NTTU_GridView_Row"]').map{|tr| tr}.each do |tr|
      data = tr.css('td').map{|td| td.text}
      syllabus_url = @query_url + tr.css('td a').map{|a| a[:onclick].split('\'')[1]}[0]
      course_id = tr.css('td a').map{|a| a[:onclick].scan(/[i][d]\=(\w+)/)[0][0]}[0]

      time_period_regex = /(?<day>[1234567])(?<period>\w)/
      course_time_location = data[12].scan(time_period_regex)

      course_days, course_periods, course_locations = [], [], []
      course_time_location.each do |k, v|
        course_days << k.to_i
        course_periods << PERIODS[v]
        course_locations << data[13]    # 上課場地(人數)
      end

      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: data[4],    # 課程名稱
        lecturer: data[11],    # 授課教師
        credits: data[6].to_i,    # 學分數
        code: "#{@year}-#{@term}-#{course_id}-?(#{data[3]})?",
        # general_code: data[3],    # 選課代碼
        url: syllabus_url,    # 課程大綱之類的連結
        required: data[0].include?('必'),    # 必修或選修
        department: data[1],    # 開課系所
        # department_code: department_code,
        # course_type: data[2],    # 課程類型
        # people_maximum: data[7],    # 人數上限
        # people_minimum: data[8],    # 人數下限
        # people_1: data[9],    # 選課人數
        # people_2: data[10],    # 修課人數
        # pre_course: data[14],    # 先修課程
        # mix_class: data[15],    # 合班
        # note: data[16],    # 備註說明
        # course_limit: data[17],    # 選課限制
        # special: data[18],    # 特殊課程
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

# crawler = NationalTaiTungUniversityCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
