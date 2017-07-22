require 'crawler_rocks'
require 'json'
require 'pry'

class DaYehUniversityCrawler

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
  "A" => 10,
  "B" => 11,
  "C" => 12,
  "D" => 13,
  "E" => 14,
  }

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil

		@year = year-1911
		@term = term
		@update_progress_proc = update_progress
		@after_each_proc = after_each

		@query_url = 'http://syl.dyu.edu.tw/index.php'
	end

	def courses
  @courses = []

  # 依系所別
  r = RestClient.get(@query_url)
  doc = Nokogiri::HTML(r)

  doc.css('select[id="edu_no"] option:nth-child(n+2)').map{|opt| [opt[:value], opt.text]}.each do |edu_c, edu_n|
   
   r = RestClient.post("http://syl.dyu.edu.tw/sl_college.php", {"edu" => edu_c })
   doc = Nokogiri::HTML(r)

   doc.css('select[id="college_no"] option:nth-child(n+2)').map{|opt| [opt[:value], opt.text]}.each do |col_c, col_n|

    r = RestClient.post("http://syl.dyu.edu.tw/sl_dept.php", {"col" => col_c }, cookies: r.cookies)
    doc = Nokogiri::HTML(r)

    doc.css('select[id="dept_no"] option:nth-child(n+2)').map{|opt| [opt[:value], opt.text]}.each do |dept_c, dept_n|

     r = RestClient.post("http://syl.dyu.edu.tw/sl_cour.php", {
      "smye" => @year,
      "smty" => @term,
      "edu_no" => edu_c,
      "college_no" => col_c,
      "dept_no" => dept_c,
      })
     doc = Nokogiri::HTML(r)

     course_temp(doc, dept_c, dept_n)
    end
   end
  end

  # 共同教學中心 有日間部與進修部的區別(進修部在note會有"進修")
  r = RestClient.post('http://syl.dyu.edu.tw/sl_group_all.php', {"smye" => @year, "smty" => @term, "day_no" => 1})
  doc = Nokogiri::HTML(r)

  doc.css('select[name="group_no"] option').map{|opt| [opt[:value], opt.text]}.each do |group_c, group_n|
   r = RestClient.post('http://syl.dyu.edu.tw/sl_cour.php', {"smye" => @year, "smty" => @term, "day_no" => 1, "group_no" => group_c })
   doc = Nokogiri::HTML(r)

   course_temp(doc, group_c, group_n)
# binding.pry
  end
  @courses
 end

 def course_temp(doc, dept_c, dept_n)
  doc.css('div[class="row"]').map{|row| row}.each do |row|
   data = row.css('div').map{|td| td.text}
   data[-1] = "http://syl.dyu.edu.tw/" + row.css('div a').map{|a| a[:href]}[0]
   course_code = Nokogiri::HTML(RestClient.get(data[-1])).css('#cour1 > div:nth-child(4) > div.row_info').text.split('/')[-1][1..-2]

   time_period_regex = /(?<day>[一二三四五六日])+\)(?<period>\w+)\/(?<loc>.+)/
   course_time_location = Hash[data[6].split('、').map{|time| time.scan(time_period_regex)}]

   # 把 course_time_location 轉成資料庫可以儲存的格式
   course_days = []
   course_periods = []
   course_locations = []
   course_time_location.each do |k, v|
    for i in 0..k[1].length - 1
     course_days << DAYS[k[0]]
     course_periods << PERIODS[k[1][i]]
     course_locations << k[2]
    end
   end

   course = {
    year: @year + 1911,    # 西元年
    term: @term,    # 學期 (第一學期=1，第二學期=2)
    name: data[3],    # 課程名稱
    lecturer: data[4],    # 授課教師
    credits: data[1].split('/')[0].to_i,    # 學分數
    code: "#{@year + 1911}-#{@term}-#{data[2]}-?(#{course_code})?",
    # general_code: course_code,    # 選課代碼
    url: data[-1],    # 課程大綱之類的連結
    required: data[1].split('/')[-1].include?('必'),    # 必修或選修
    department: dept_n,    # 開課系所
    # department_code: dept_c,
    note: data[7],    # 備註
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

# crawler = DaYehUniversityCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
