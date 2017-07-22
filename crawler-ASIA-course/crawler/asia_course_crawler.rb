require 'crawler_rocks'
require 'json'
require 'pry'

class AsiaUniversityCrawler

# 上課時間
# 【1】08:10~09:00 
# 【2】09:10~10:00
# 【3】10:10~11:00 
# 【4】11:10~12:00 
# 【5】13:10~14:00 
# 【6】14:10~15:00 
# 【7】15:10~16:00 
# 【8】16:10~17:00 
# 【9】17:10~18:00
# 【E】18:00-18:30
# 【10(A)】18:30~19:15
# 【11(B)】19:25~20:10
# 【12(C)】20:20~21:05
# 【13(D)】21:15~22:00 
# 【M】07:30-08:00
# 【N】12:10~13:00 

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
    "M" => 1,
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
    "E" => 12,
    "A" => 13,
    "B" => 14,
    "C" => 15,
    "D" => 16,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://webs.asia.edu.tw/courseinfo/'
  end

  def courses
    @courses = []

    r = RestClient.post(@query_url + 'courselist.asp', {
      "cos_setyear_q" => @year - 1911,
      "cos_setterm_q" => @term,
      "Qry" => "送出查詢",
      })
    doc = Nokogiri::HTML(r)

    course_id = 1

    (1..doc.css('table[id="Table4"] td[align="center"]').text.split('/')[-1].to_i).each do |page|
      if page != 1
        r = RestClient.post(@query_url + 'courselist.asp', {
          "GoToPage1" => page-1,
          "GoToPage2" => page-1,
          "flg" => "Y",
          "page" => page,
          "cos_setyear_q" => @year - 1911,
          "cos_setterm_q" => @term,
          })
        doc = Nokogiri::HTML(r)

        course_id += 1
      end

      doc.css('table[width="99%"]:not(:first-child) tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
        data = tr.css('td').map{|td| td.text}
        syllabus_url = @query_url + tr.css('td a').map{|a| a[:href]}[0]

        time_period_regex = /(?<day_peri>[一二三四五六日]\)\w+)\s(?<loc>\w+)/
        course_time_location = Hash[ data[7].scan(time_period_regex) ]

        course_days, course_periods, course_locations = [], [], []
        course_time_location.each do |k, v|
          for i in 1..k[2..-1].length
            course_days << DAYS[k[0]]
            course_periods << PERIODS[k[i + 1]]
            course_locations << v
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[2],    # 課程名稱
          lecturer: data[6],    # 授課教師
          credits: data[4].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_id}-?(#{data[1]})?",
          # general_code: data[1],    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結
          required: data[3].include?('必'),    # 必修或選修
          department: data[0],    # 開課系所
          # note: data[9],
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
    end
    @courses
  end

end

# crawler = AsiaUniversityCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
