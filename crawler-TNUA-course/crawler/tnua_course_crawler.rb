require 'crawler_rocks'
require 'json'
require 'pry'

class TaipeiNationalUniversityOfTheArtsCrawler

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
    "X" => 1,
    "1" => 2,
    "2" => 3,
    "3" => 4,
    "4" => 5,
    "N" => 6,
    "5" => 7,
    "6" => 8,
    "7" => 9,
    "8" => 10,
    "9" => 11,
    "A" => 12,
    "B" => 13,
    "C" => 14,
    "D" => 15,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://203.71.172.85/Public/Public.aspx'
  end

  def courses
    @courses = []

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    dep = Hash[doc.css('select[name="PublicAcx1$CourseQueryAcxTNUA1$ddl_Dept"] option:nth-child(n+2)').map{|opt| [opt[:value], opt.text]}]
    dep.each do |dep_c, dep_n|

      r = RestClient.post(@query_url, {
        "ScriptManager1" => "PublicAcx1$CourseQueryAcxTNUA1$UpdatePanel3|PublicAcx1$CourseQueryAcxTNUA1$ddl_Dept",
        "__EVENTTARGET" => "PublicAcx1$CourseQueryAcxTNUA1$ddl_Dept",
        # "__EVENTARGUMENT" => "",
        # "__LASTFOCUS" => "",
        "__VIEWSTATE" => hidden["__VIEWSTATE"],
        "__VIEWSTATEENCRYPTED" => "",
        "PublicAcx1$CourseQueryAcxTNUA1$ddlYear" => @year - 1911,
        "PublicAcx1$CourseQueryAcxTNUA1$ddl_Semi" => @term,
        "PublicAcx1$CourseQueryAcxTNUA1$ddl_Dept" => dep_c,
        "PublicAcx1$CourseQueryAcxTNUA1$ddCredit" => "-1",
        "PublicAcx1$CourseQueryAcxTNUA1$ddYearCos" => "0",
        "PublicAcx1$CourseQueryAcxTNUA1$ddWeek" => "0",
        "PublicAcx1$CourseQueryAcxTNUA1$ddSSect" => "0",
        "PublicAcx1$CourseQueryAcxTNUA1$ddESect" => "999",
        # "PublicAcx1$CourseQueryAcxTNUA1$edtTitle" => "",
        # "PublicAcx1$CourseQueryAcxTNUA1$edtName" => "",
        "PublicAcx1$CourseQueryAcxTNUA1$ddSort" => "2",
        "__ASYNCPOST" => "true",
        "" => "",
        }, {"User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/43.0.2357.130 Chrome/43.0.2357.130 Safari/537.36"})

      hidden = Hash[r.split('hiddenField')[1..-1].map{|hidden| [hidden.split('|')[1], hidden.split('|')[2]]}]

      r = RestClient.post(@query_url, {
        "ScriptManager1" => "PublicAcx1$CourseQueryAcxTNUA1$UpdatePanel6|PublicAcx1$CourseQueryAcxTNUA1$LB_Query",
        "__EVENTTARGET" => "PublicAcx1$CourseQueryAcxTNUA1$LB_Query",
        # "__EVENTARGUMENT" => "",
        # "__LASTFOCUS" => "",
        "__VIEWSTATE" => hidden["__VIEWSTATE"],
        "__VIEWSTATEENCRYPTED" => "",
        "PublicAcx1$CourseQueryAcxTNUA1$ddlYear" => @year - 1911,
        "PublicAcx1$CourseQueryAcxTNUA1$ddl_Semi" => @term,
        "PublicAcx1$CourseQueryAcxTNUA1$ddl_Dept" => dep_c,
        "PublicAcx1$CourseQueryAcxTNUA1$ddCredit" => "-1",
        "PublicAcx1$CourseQueryAcxTNUA1$ddYearCos" => "0",
        "PublicAcx1$CourseQueryAcxTNUA1$ddWeek" => "0",
        "PublicAcx1$CourseQueryAcxTNUA1$ddSSect" => "0",
        "PublicAcx1$CourseQueryAcxTNUA1$ddESect" => "999",
        # "PublicAcx1$CourseQueryAcxTNUA1$edtTitle" => "",
        # "PublicAcx1$CourseQueryAcxTNUA1$edtName" => "",
        "PublicAcx1$CourseQueryAcxTNUA1$ddSort" => "2",
        "__ASYNCPOST" => "true",
        "" => "",
        }, {"User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/43.0.2357.130 Chrome/43.0.2357.130 Safari/537.36"})
      doc = Nokogiri::HTML(r)

      doc.css('table[id="PublicAcx1_CourseQueryAcxTNUA1_GridView1"] tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
        data = tr.css('td').map{|td| td.text}

        time_period_regex = /(?<day>[一二三四五六日])\)(?<period>(\w+\,?)+)/

        course_days, course_periods, course_locations = [], [], []
        data[7].scan(time_period_regex).each do |day, period|
          period.split(',').each do |p|
            course_days << DAYS[day]
            course_periods << PERIODS[p]
            course_locations << data[8]
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[1],  # 課程名稱
          lecturer: data[6],  # 授課教師
          credits: data[4].to_i,  # 學分數
          code: "#{@year}-#{@term}-#{dep_c}-?(#{data[0]})?",
          # general_code: old_course.cos_code,    # 選課代碼
          required: data[3].include?('必'),    # 必修或選修
          department: dep_n,    # 開課系所
          # department_code: department_code,
          # notes: data[13],  # 備註說明
          # department_type: data[2],  # 班別
          # department_term: data[5],  # 學期別
          # course_type: data[9],  # 課程領域
          # people_maximum: data[10],  # 人數上限
          # people: data[11],  # 已選人數
          # for_who: data[12],  # 選課對象
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
    # binding.pry
    @courses
  end
end

# crawler = TaipeiNationalUniversityOfTheArtsCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
