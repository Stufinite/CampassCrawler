require 'crawler_rocks'
require 'json'
require 'pry'

class UtaipeiCourseCrawler

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
    "14" => 14,
    "A" => 11,
    "B" => 12,
    "C" => 13,
    "D" => 14,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://210.71.24.139/utaipei/ag_pro/ag304_face.jsp?uid=null'
  end

  def courses

    @courses = []

    first_time_list = ['ZZ40', '2410', 'XC00', '9711', '9747', '7100', '5700', '9200']  #for load page

    query_url = %x(curl -s 'http://210.71.24.139/utaipei/ag_pro/ag304_face.jsp?uid=null' --compressed)
    doc = Nokogiri::HTML(query_url)

    #find department's id
    select = doc.css('select')[1]
    option_times = select.css('option').count
    for i in 1..option_times
      #select department
      dep_id = query_url.split('select id')[2].split('value=')[i][1..2]
      unt_id = first_time_list[i - 1]
      temp_url = %x(curl -s 'http://210.71.24.139/utaipei/ag_pro/ag304_face.jsp' --data 'yms_yms=#{@year-1911}%23#{@term}&dpt_id=#{dep_id}&unt_id=#{unt_id}&data=%E5%90%84%E5%A4%A7%E6%A8%93%E4%BB%A3%E7%A2%BC%E8%AA%AA%E6%98%8E%E8%A1%A8%3CHR%3E%3Ctable+border%3D0+width%3D97%25+align%3Dcenter%3E%3Ctr%3E%3Ctd%3E%E8%A1%8C%E6%94%BF%E5%A4%A7%E6%A8%93-C%2810%29%3C%2Ftd%3E%3Ctd%3E%E9%B4%BB%E5%9D%A6%E6%A8%93-B%2811%29%3C%2Ftd%3E%3C%2Ftr%3E%3Ctr%3E%3Ctd%3E%E7%A7%91%E8%B3%87%E5%A4%A7%E6%A8%93-D%2812%29%3C%2Ftd%3E%3Ctd%3E%E8%A9%A9%E6%AC%A3%E9%A4%A8-E%2813%29%3C%2Ftd%3E%3Ctd%3E%E9%AB%94%E8%82%B2%E9%A4%A8-A%2814%29%3C%2Ftd%3E%3C%2Ftr%3E%3Ctr%3E%3Ctd%3E%E6%A0%A1%E5%A4%96%E5%A0%B4%E5%9C%B0%2815%29%3C%2Ftd%3E%3Ctd%3E%E5%AE%A4%E5%A4%96%E5%85%B6%E4%BB%96%E8%A1%93%E7%A7%91%E5%A0%B4%E5%9C%B0%288%29%3C%2Ftd%3E%3Ctd%3E%E8%97%9D%E8%A1%93%E9%A4%A8%28A%29%3C%2Ftd%3E%3C%2Ftr%3E%3Ctr%3E%3Ctd%3E%E4%B8%AD%E6%AD%A3%E5%A0%82%28B%29%3C%2Ftd%3E%3Ctd%3E%E5%8B%A4%E6%A8%B8%E6%A8%93%28C%29%3C%2Ftd%3E%3Ctd%3E%E5%85%AC%E8%AA%A0%E6%A8%93%28G%29%3C%2Ftd%3E%3C%2Ftr%3E%3Ctr%3E%3Ctd%3E%E5%9C%96%E6%9B%B8%E9%A4%A8%28L%29%3C%2Ftd%3E%3Ctd%3E%E9%9F%B3%E6%A8%82%E9%A4%A8%28M%29%3C%2Ftd%3E%3Ctd%3E%E5%AD%B8%E7%94%9F%E5%AE%BF%E8%88%8D%28R%29%3C%2Ftd%3E%3C%2Ftr%3E%3Ctr%3E%3Ctd%3E%E7%A7%91%E5%AD%B8%E9%A4%A8%28S%29%3C%2Ftd%3E%3Ctd%3E%E8%A1%8C%E6%94%BF%E5%A4%A7%E6%A8%93%28%E5%8D%9A%E6%84%9B%E6%A0%A1%E5%8D%80%29%28T%29%3C%2Ftd%3E%3Ctd%3E%E5%85%B6%E5%AE%83%28%E5%8D%9A%E6%84%9B%E6%A0%A1%E5%8D%80%29%28X%29%3C%2Ftd%3E%3C%2Ftr%3E%3Ctr%3E%3Ctd%3E%E6%93%8D%E5%A0%B4%28%E5%8D%9A%E6%84%9B%E6%A0%A1%E5%8D%80%29%28Y%29%3C%2Ftd%3E%3C%2Ftr%3E%3C%2Ftable%3E&ls_year=#{@year-1911}&ls_sms=#{@term}&uid=null' --compressed)

      #find unit's id
      option_times2 = temp_url.split('select id')[3].split('value').count - 9
      for j in 1..option_times2
        #select unit
        unt_id = temp_url.split('select id')[3].split('value')[j][2..5]
        temp_url2 = %x(curl -s 'http://210.71.24.139/utaipei/ag_pro/ag304_02.jsp' --data 'yms_yms=#{@year-1911}%23#{@term}&dpt_id=#{dep_id}&unt_id=#{unt_id}&data=%E5%90%84%E5%A4%A7%E6%A8%93%E4%BB%A3%E7%A2%BC%E8%AA%AA%E6%98%8E%E8%A1%A8%3CHR%3E%3Ctable+border%3D0+width%3D97%25+align%3Dcenter%3E%3Ctr%3E%3Ctd%3E%E8%A1%8C%E6%94%BF%E5%A4%A7%E6%A8%93-C%2810%29%3C%2Ftd%3E%3Ctd%3E%E9%B4%BB%E5%9D%A6%E6%A8%93-B%2811%29%3C%2Ftd%3E%3C%2Ftr%3E%3Ctr%3E%3Ctd%3E%E7%A7%91%E8%B3%87%E5%A4%A7%E6%A8%93-D%2812%29%3C%2Ftd%3E%3Ctd%3E%E8%A9%A9%E6%AC%A3%E9%A4%A8-E%2813%29%3C%2Ftd%3E%3Ctd%3E%E9%AB%94%E8%82%B2%E9%A4%A8-A%2814%29%3C%2Ftd%3E%3C%2Ftr%3E%3Ctr%3E%3Ctd%3E%E6%A0%A1%E5%A4%96%E5%A0%B4%E5%9C%B0%2815%29%3C%2Ftd%3E%3Ctd%3E%E5%AE%A4%E5%A4%96%E5%85%B6%E4%BB%96%E8%A1%93%E7%A7%91%E5%A0%B4%E5%9C%B0%288%29%3C%2Ftd%3E%3Ctd%3E%E8%97%9D%E8%A1%93%E9%A4%A8%28A%29%3C%2Ftd%3E%3C%2Ftr%3E%3Ctr%3E%3Ctd%3E%E4%B8%AD%E6%AD%A3%E5%A0%82%28B%29%3C%2Ftd%3E%3Ctd%3E%E5%8B%A4%E6%A8%B8%E6%A8%93%28C%29%3C%2Ftd%3E%3Ctd%3E%E5%85%AC%E8%AA%A0%E6%A8%93%28G%29%3C%2Ftd%3E%3C%2Ftr%3E%3Ctr%3E%3Ctd%3E%E5%9C%96%E6%9B%B8%E9%A4%A8%28L%29%3C%2Ftd%3E%3Ctd%3E%E9%9F%B3%E6%A8%82%E9%A4%A8%28M%29%3C%2Ftd%3E%3Ctd%3E%E5%AD%B8%E7%94%9F%E5%AE%BF%E8%88%8D%28R%29%3C%2Ftd%3E%3C%2Ftr%3E%3Ctr%3E%3Ctd%3E%E7%A7%91%E5%AD%B8%E9%A4%A8%28S%29%3C%2Ftd%3E%3Ctd%3E%E8%A1%8C%E6%94%BF%E5%A4%A7%E6%A8%93%28%E5%8D%9A%E6%84%9B%E6%A0%A1%E5%8D%80%29%28T%29%3C%2Ftd%3E%3Ctd%3E%E5%85%B6%E5%AE%83%28%E5%8D%9A%E6%84%9B%E6%A0%A1%E5%8D%80%29%28X%29%3C%2Ftd%3E%3C%2Ftr%3E%3Ctr%3E%3Ctd%3E%E6%93%8D%E5%A0%B4%28%E5%8D%9A%E6%84%9B%E6%A0%A1%E5%8D%80%29%28Y%29%3C%2Ftd%3E%3C%2Ftr%3E%3C%2Ftable%3E&ls_year=#{@year-1911}&ls_sms=#{@term}&uid=null' --compressed)

        #find department code
        option_times3 = temp_url2.split('go_next').count - 1

        if option_times3 > 0

          for k in 2..option_times3
            #select department code
            department_code = temp_url2.split('go_next')[k][2..9]

            url = %x(curl -s 'http://210.71.24.139/utaipei/ag_pro/ag304_03.jsp' --data 'arg01=#{@year-1911}&arg02=#{@term}&arg=#{department_code}&uid=null' --compressed)
            doc = Nokogiri::HTML(url)

            doc.css('table')[0].css('tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
              data = tr.css('td').map{|td| td.text}
              data[11] = "http://210.71.24.139/utaipei/ag_pro/ag064_print.jsp" + "?arg01=#{@year - 1911}&arg02=#{@term}&arg04=#{tr.css('td').map{|a| a[:onclick]}[-1].split('\'')[5]}"

              time_period_regex = /(?<time>\(([一二三四五六日])\)([\dABCDEFG\-]+)*?)\((?<loc>[^\)]+?)\)/
# puts i,j,k
              course_days, course_periods, course_locations = [], [], []
              data[8].scan(time_period_regex).each do |time, loc|
                if time.scan(/\)(.+)/)[0] != nil
                  (PERIODS[time.scan(/\)(.+)/)[0][0].split('-')[0]]..PERIODS[time.scan(/\)(.+)/)[0][0].split('-')[-1]]).each do |period|
                    course_days << DAYS[time.scan(/[一二三四五六日]/)[0]]
                    course_periods << period
                    course_locations << loc
                  end
                end
                teacher = data[8].split(' ')[0]
                data[8].split(' ').each do |find_teacher|
                  teacher += "," + find_teacher.scan(/\S\S\S\)(\S+)/)[0][0] if find_teacher.scan(/\S\S\S\)(\S+)/)[0] != nil
                end
                data[8] = teacher
              end
# !!!上課時間跟老師的資料存起來有問題!!!超過九個課...
              course = {
                year: @year,    # 西元年
                term: @term,    # 學期 (第一學期=1，第二學期=2)
                name: data[1],    # 課程名稱
                lecturer: data[8],    # 授課教師
                credits: data[3].to_i,    # 學分數
                code: "#{@year}-#{@term}-#{department_code}-?(#{data[0].scan(/\w+/)[0]})?",
                # general_code: old_course.cos_code,    # 選課代碼
                url: data[11],    # 課程大綱之類的連結
                required: data[5].include?('必'),    # 必修或選修
                department: doc.css('font')[1].text,    # 開課系所
                # department_code: department_code,
                # group: td[2].text , #分組
                # hours: td[4].text,  #時數
                # department_term: td[6].text,  #開課別
                # campus: td[7].text,  #校區
                # field: td[9].text,  #領域類
                # sex_required: td[10].text,  #限制性別
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
        end
      end
    end
    @courses
  end
end

# crawler = UtaipeiCourseCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
