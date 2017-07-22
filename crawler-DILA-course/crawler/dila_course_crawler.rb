require 'crawler_rocks'
require 'json'
require 'pry'
require 'uri'

class DharmaDrumInstituteOfLiberalArtsCrawler

# 早坐   04:50|05:50
# 早課   06:00|06:40
# 第1節  08:10|09:00
# 第2節  09:10|10:00
# 第3節  10:10|11:00
# 第4節  11:10|12:00
# 午     12:10|13:00
# 第5節  13:10|14:00
# 第6節  14:10|15:00
# 第7節  15:10|16:00
# 第8節  16:10|17:00
# 晚     17:10|18:00
# 第9節  18:10|19:00
# 第10節 19:10|20:00
# 晚課   20:00|20:40
# 晚坐   21:00|21:40

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
    "早坐" => 1,
    "早課" => 2,
    "01" => 3,
    "02" => 4,
    "03" => 5,
    "04" => 6,
    "午" => 7,
    "05" => 8,
    "06" => 9,
    "07" => 10,
    "08" => 11,
    "晚" => 12,
    "09" => 13,
    "10" => 14,
    "晚課" => 15,
    "晚坐" => 16,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://ecampus.dila.edu.tw/ddb/'
  end

  def courses
    @courses = []

    r = RestClient.get(@query_url + 'LoginDDB.aspx')

    cookie = "49BAC005-7D5B-4231-8CEA-16939BEACD67=guest; 2BCD80435-67EA-B52D-9E10-234EB74D1A165DCA=ddm; B2380ACE1-3B7A-E1D0-79AC-4512BAC397DB486D=DDM; ASP.NET_SessionId=#{r.cookies["ASP.NET_SessionId"]}"

    hidden = Hash[Nokogiri::HTML(r).css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = %x(curl -s "#{@query_url}LoginDDB.aspx" -H "Cookie: #{cookie}" --data "__LASTFOCUS=&__VIEWSTATE=#{URI.escape("#{hidden["__VIEWSTATE"]}", "/=+")}&__EVENTTARGET=&__EVENTARGUMENT=&__EVENTVALIDATION=#{URI.escape("#{hidden["__EVENTVALIDATION"]}", "/=+")}&txtUserName=guest&txtPassword=&ddlSolution=DDM&ddlDataBase=ddm&OKButton=%E7%99%BB%E5%85%A5" --compressed)

    r = RestClient.get(@query_url + 'DDM_S32/P320001.aspx', {"Cookie" => cookie })
    doc = Nokogiri::HTML(r)

    doc.css('select[name="ctl00$SearchContent$Wddl_obligation"] option:nth-child(n+2)').map{|opt| [opt[:value], opt.text]}.each do |dept_c, dept_n|

      doc = Nokogiri::HTML(RestClient.get(@query_url + 'DDM_S32/P320001.aspx', {"Cookie" => cookie }))

      doc = Nokogiri::HTML(post(doc, dept_c, cookie))

      doc.css('tr[class="PageRow"] tr td').map{|td| td.text}.each do |page|

        doc = Nokogiri::HTML(post(doc, dept_c, cookie, eventtarget: "ctl00$wgvContent$wgvMaster", eventargument: "Page$#{page}")) if page != "1"

        doc.css('table[id="ctl00_wgvContent_wgvMaster"] tr:nth-child(n+2):not(:last-child)').map{|tr| tr}.each do |tr|
          data = tr.css('td').map{|td| td.text}
          data.shift if page != "1"
          lecturer = data[9].split('室 ')[-1].split('殿 ')[-1].split('場 ')[-1].split('苑 ')[-1].split(') ')[-1]
          lecturer = nil if lecturer.include?("教室") or lecturer.include?("F)")

          time_period_regex = /\((?<day>[一二三四五六日])\)\s(?<period>[01早午晚][\d坐課]?\-?[01早午晚]?[\d坐課]?)\s\s?(?<loc>\S+(\s\(\w+\))?)?/
          course_time_location = data[9].scan(time_period_regex)

          course_days, course_periods, course_locations = [], [], []
          course_time_location.each do |day, period, loction|
            (PERIODS[period.split('-')[0]]..PERIODS[period.split('-')[-1]]).each do |p|
              course_days << DAYS[day]
              course_periods << p
              course_locations << loction
            end
          end


          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[3],    # 課程名稱
            lecturer: lecturer,    # 授課教師
            credits: data[6].to_i,    # 學分數
            code: "#{@year}-#{@term}-#{dept_c}-?(#{data[0].scan(/\w+/)[0]})?",
            # general_code: data[0],    # 選課代碼
            # url: ,    # 課程大綱之類的連結(不能直接從外部連結，會顯示登入逾時)
            required: data[5].include?('必'),    # 必修或選修
            department: data[1],    # 開課系所
            # department_code: dept_c,
            # note: data[10],
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
# binding.pry if dept_c == "BB03"
        end
      end
    end
    @courses
  end

  def post(doc, dept_c, cookie, eventtarget: "ctl00$WebNavigator1", eventargument: "cmdSearch")
    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = RestClient.post(@query_url + 'DDM_S32/P320001.aspx', hidden.merge({
      "__EVENTTARGET" => eventtarget,
      "__EVENTARGUMENT" => eventargument,
      "ctl00$SearchContent$tb_year" => @year - 1911,
      "ctl00$SearchContent$tb_sms" => @term,
      "ctl00$SearchContent$Wddl_obligation" => dept_c,
      "ctl00$SearchContent$Wddl_weekday" => "0",
      }), {"Cookie" => cookie })
  end
end

# crawler = DharmaDrumInstituteOfLiberalArtsCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
