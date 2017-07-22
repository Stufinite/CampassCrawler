require 'crawler_rocks'
require 'json'
require 'pry'

class NationalTaiwanSportUniversityCrawler

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://one.ntsu.edu.tw/ntsu/outside.aspx?mainPage=LwBBAHAAcABsAGkAYwBhAHQAaQBvAG4ALwBUAEsARQAvAFQASwBFADIAMgAvAFQASwBFADIAMgAxADAAXwAuAGEAcwBwAHgAPwBwAHIAbwBnAGMAZAA9AFQASwBFADIAMgAxADAA"
    @result_url = "http://one.ntsu.edu.tw/NTSU//Application/TKE/TKE22/TKE2210_01.aspx"
  end

  def courses
    @courses = []

    hidden = {}
    # 我不懂這個網頁怎會這樣...有時候網頁會連不上，多跑個幾次試試看，結果就可以了！！
    while hidden == {}
      r = RestClient.get(@query_url)
      cookies = r.cookies

      r = RestClient.get(@result_url, cookies:r.cookies)
      doc = Nokogiri::HTML(r)

      hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]
    end
    @as_fid = doc.css('input[name="as_fid"]').map{|a| a[:value]}[0]

    while hidden != nil
      begin
        r = post(hidden, @year, @term, cookies, "QUERY_BTN1", qUERY_BTN1: "QUERY_BTN1", qUERY_TYPE: 1, qUERY_BTN1_opt: "開課單位查詢", page_size: 2000)
        hidden = nil
      rescue => e
        e.response
      end
    end
    doc = Nokogiri::HTML(r)

    doc.css('table[id="DataGrid"] tr:not(:first-child)').map{|tr| tr}.each do |tr|
      data = tr.css('td').map{|td| td.text}

      course_days, course_periods, course_locations = [], [], []
      data[10].scan(/(?<day>[1234567])(?<period>\d+)/).each do |day, period|
        course_days << day.to_i
        course_periods << period.to_i
        course_locations << data[11]
      end

      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: data[3],    # 課程名稱
        lecturer: data[6],    # 授課教師
        credits: data[8].to_i,    # 學分數
        code: "#{@year}-#{@term}-#{data[0]}-?(#{data[2].scan(/\S+/)[0]})?",
        # general_code: data[2].scan(/\S+/)[0],    # 選課代碼
        required: data[9].include?('必'),    # 必修或選修
        department: "#{data[4]}" + " " + "#{data[5]}",             # 開課系所
        # lecturer_department: data[7],    # 教師聘任單位
        # people: data[12],                # 人數
        # people_limit: data[13],          # 人數上下限
        # intern: data[14],                # 實習(應該是時數)
        # hours: data[15],                 # 時數
        # mix: data[16],                   # 合開
        # department_term: data[17],       # 期限(學期or學年)
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
  # binding.pry
    end
    @courses
  end

  def post(hidden, year, term, cookies, scriptManager1, qUERY_BTN1: nil, qUERY_TYPE: nil, qUERY_BTN1_opt: nil, page_size: 20)
    r = RestClient.post(@result_url, {
      "ScriptManager1" => "AjaxPanel|#{scriptManager1}",
      # "__EVENTTARGET" => scriptManager1,
      # "__EVENTARGUMENT" => "",
      # "__LASTFOCUS" => "",
      "__VIEWSTATE" => hidden["__VIEWSTATE"],
      "__VIEWSTATEGENERATOR" => "13021BF5",
      "__VIEWSTATEENCRYPTED" => "",
      "__EVENTVALIDATION" => hidden["__EVENTVALIDATION"],
      # "ActivePageControl" => "",
      # "ColumnFilter" => "",
      # "SAYEAR" => "",
      "QUERY_TYPE" => "#{qUERY_TYPE}",
      "FacultyType" => "2",
      "TabCnt" => "1",
      "Q_AYEAR" => year - 1911,
      "Q_SMS" => term,
      "QUERY_TYPE1" => "1",
      # "Q_DEGREE_CODE" => "",
      # "Q_COLLEGE_CODE" => "",
      # "Q_FACULTY_CODE" => "",
      # "Q_GRADE" => "",
      # "Q_CLASSID" => "",
      "PC$PageSize" => page_size,
      "PC$PageNo" => "1",
      "PC2$PageSize" => page_size,
      "PC2$PageNo" => "1",
      "as_fid" => @as_fid,
      "__ASYNCPOST" => "true",
      "#{qUERY_BTN1}" => "#{qUERY_BTN1_opt}",
      }, {
        :cookies => cookies,
        # "Origin" => "http://one.ntsu.edu.tw",
        # "Accept-Encoding" => "gzip, deflate",
        # "Accept-Language" => "zh-TW,zh;q=0.8,en-US;q=0.6,en;q=0.4,zh-CN;q=0.2",
        "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/43.0.2357.130 Chrome/43.0.2357.130 Safari/537.36",
        # "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8",
        # "Accept" => "*/*",
        # "Cache-Control" => "no-cache",
        # "X-Requested-With" => "XMLHttpRequest",
        # "Connection" => "keep-alive",
        # "X-MicrosoftAjax" => "Delta=true",
        # "Referer" => "http://one.ntsu.edu.tw/NTSU//Application/TKE/TKE22/TKE2210_01.aspx",
        })
  end
end

# crawler = NationalTaiwanSportUniversityCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
