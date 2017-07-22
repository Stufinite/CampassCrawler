require 'crawler_rocks'
require 'json'
require 'pry'
require 'iconv'

class NationalTaipeiUniversityOfEducationCrawler

  PERIODS = {
    "01" => 1,
    "02" => 2,
    "03" => 3,
    "04" => 4,
    "0N" => 5,
    "05" => 6,
    "06" => 7,
    "07" => 8,
    "08" => 9,
    "0E" => 10,
    "09" => 11,
    "10" => 12,
    "11" => 13,
    "12" => 14,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://apstu.ntue.edu.tw/Secure/default.aspx'
    @ic = Iconv.new('utf-8//translit//IGNORE', 'utf-8')
  end

  def courses
    @courses = []

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = RestClient.post(@query_url, hidden.merge({
      "LoginDefault$txtScreenWidth" => "1360",
      "LoginDefault$txtScreenHeight" => "768",
      "LoginDefault$ibtLoginGuest.x" => "20",
      "LoginDefault$ibtLoginGuest.y" => "20",
      }) )

    cookie = "ASP.NET_SessionId=#{r.cookies["ASP.NET_SessionId"]}; .PaAuth=#{r.cookies[".PaAuth"]}"

    @query_url = 'http://apstu.ntue.edu.tw/Message/Main.aspx'
    r = RestClient.get @query_url, {"Cookie" => cookie }
    doc = Nokogiri::HTML(@ic.iconv(r))

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = RestClient.post(@query_url, hidden.merge({
      "CommonHeader$txtMsg" => "目前學年期為#{doc.css('title').text.split(' ')[1]}#{doc.css('title').text.split(' ')[2]}",
      "MenuDefault$dgData$ctl02$ibtMENU_ID.x" => "100",
      "MenuDefault$dgData$ctl02$ibtMENU_ID.y" => "20",
      }), {"Cookie" => cookie })
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    @query_url = "http://apstu.ntue.edu.tw/Message/SubMenuPage.aspx"
    r = RestClient.post(@query_url, hidden.merge({"__EVENTTARGET" => "SubMenu$dgData$ctl02$ctl00"}), {"Cookie" => cookie })

    @query_url = 'http://apstu.ntue.edu.tw/A04/A0428S3Page.aspx'
    r = RestClient.get @query_url, {"Cookie" => cookie }
    doc = Nokogiri::HTML(r)

    course_count = 0
    for page in 0..28  # 104的課程一共有29頁*50個，換頁換得很討厭omO
      if page < 10
        page = "0" + page.to_s
      elsif page > 10 && page < 19
        page = "0" + (page - 9).to_s
      elsif page > 18 && page < 21
        page = page - 9
      elsif page > 20 && page < 28
        page = "0" + (page - 18).to_s
      elsif page == 28
        page = 10
      end

      hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

      r = RestClient.post(@query_url, hidden.merge({
        "__EVENTTARGET" => "A0425S3$dgData$ctl54$ctl#{page}",
        "A0425SMenu$ddlSYSE" => "#{@year - 1911}#{@term}",
        }), {"Cookie" => cookie })
      doc = Nokogiri::HTML(r)

      doc.css('table[class="DgTable"] tr[onmouseover="OnOver(this);"]').map{|tr| tr}.each do |tr|
        data = tr.css('td').map{|td| td.text}
        data[9] = data[9].scan(/\S+/)[0]
        if data[9] != nil
          data[9] = data[9][0..data[9].length/2-1] if data[9][0..data[9].length/2-1] == data[9][(data[9].length/2)..data[9].length-1]
        end

        time_period_regex = /(?<day>[1234567])(?<period>\w\w\w\w)/
        course_time_location = data[8].scan(time_period_regex)    # !!!data[8]裡有寫單雙周!!!

        course_days, course_periods, course_locations = [], [], []
        course_time_location.each do |k, v|
          (PERIODS[v[0..1]]..PERIODS[v[2..3]]).each do |period|
            course_days << k.to_i
            course_periods << period    # !!!有些課程分單、雙周上課!!!
            course_locations << data[9]
          end
        end
        course_count += 1

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[1],    # 課程名稱
          lecturer: data[7].scan(/\S+/)[0],    # 授課教師
          credits: data[10].scan(/\d/)[0].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{course_count}-?(#{data[0].scan(/\w+/)[0]})?",
          # general_code: data[0],    # 選課代碼
          required: data[2].include?('必'),    # 必修或選修
          department: "#{data[5].scan(/\S+/)[0]}" + " " + "#{data[4].scan(/\S+/)[0]}",    # 開課系所
          # note: data[15],    # 備註   !!!這裡有寫單雙周!!!
          # department_type: data[3],    # 修別 (XX課程)
          # study_type: data[6],    # 學制
          # people_minimum: data[11],    # 人數下限
          # people_maximum: data[12],    # 人數上限
          # people_1: data[13],    # 已選人數
          # people_2: data[14],    # 選中人數
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
   # binding.pry
    end
    @courses
  end
end

# crawler = NationalTaipeiUniversityOfEducationCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
