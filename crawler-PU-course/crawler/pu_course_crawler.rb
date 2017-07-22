require 'crawler_rocks'
require 'json'
require 'pry'

class ProvidenceUniversityCrawler

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
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://alcat.pu.edu.tw/2011courseAbstract/main.php?type=mutinew&lang=zh'
  end

  def courses
    @courses = []

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)

    doc.css('select[name="opunit"] option:not(:first-child)').map{|opt| [opt[:value], opt.text]}.each do |dep_c, dep_n|

      r = RestClient.post(@query_url, {
        "ls_yearsem" => "#{@year - 1911}#{@term}",
        "selectno" => "",
        "weekday" => "",
        "section" => "",
        "cus_select" => "",
        "classattri" => "1",
        "subjname" => "",
        "teaname" => "",
        "opunit" => dep_c,
        "opclass" => "",
        "lessonlang" => "",
        "search" => "搜尋",
        "click_ok" => "Y",
        })
      doc = Nokogiri::HTML(r)

      doc.css('table[class="table_info"] tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
        next if tr.text.include?("經濟部智慧財產局校園二手教科書網")
        data = tr.css('td').map{|td| td.text}
        data[5] = data[5].scan(/\d/)[0].to_i if data[5] != nil
        syllabus_url = "http://alcat.pu.edu.tw" + tr.css('td a').map{|a| a[:href]}[0][2..-1] if tr.css('td a').map{|a| a[:href]}[0] != nil

        time_period_regex = /(?<day>[一二三四五六日])(?<peri_loc>(\　\s?(?<period>((\d+)?午?\、?)+)\：?(?<location>[伯思靜任一二計方格主體高室田游保]?[鐸源安垣研濟倫顧育校外徑場泳]?[館外池網]?\球?\場?(\d+)?))+)/
        course_days, course_periods, course_locations = [], [], []
        if data[7] != nil
          course_time_location = data[7].scan(time_period_regex)
          course_time_location.each do |k, v|
            v.scan(/(?<period>([\d午][\d]?\、?)+)\：/)[0][0].split('、').each do |period|
              course_days << DAYS[k]
              course_periods << PERIODS[period]
              course_locations << v.split('：')[-1]
            end
          end
        end

        ###!!!課程代碼重複是因為一個課程有多位教師(官方設定的)!!!

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[3].scan(/(?<name>(\S+\s?)+)/)[0][0],    # 課程名稱
          lecturer: data[6].scan(/\S+/)[0],        # 授課教師
          credits: data[5],    # 學分數
          code: "#{@year}-#{@term}-#{dep_c}-?(#{data[0].scan(/\w+/)[0]})?",
          # general_code: data[0],    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結
          required: data[2].include?('必'),    # 必修或選修
          department: "#{dep_n}" + " " + "#{data[1].scan(/\S+/)[0]}",        # 開課系所
          # department_code: dep_c,
          # note: data[9],           # 備註說明
          # term_type: data[4],       # 學期別
          # people_last: data[8],     # 目前餘額(人數)
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
      # binding.pry if dep_c == "25"
      end
    end
    @courses
  end
end

# crawler = ProvidenceUniversityCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
