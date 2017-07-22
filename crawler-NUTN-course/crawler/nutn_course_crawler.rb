require 'crawler_rocks'
require 'json'
require 'pry'

class NutnCourseCrawler

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
    "F" => 15,
    "G" => 16,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://academics.nutn.edu.tw/cos_guide/query_course.aspx'
  end

  def courses
    @courses = []

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)
    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    # 通識課程
    doc = Nokogiri::HTML(post(hidden))
    course_temp(doc)

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)
    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    # 大學課程
    doc.css('select[name="TabContainer1$TabPanel2$lstcollege1"] option:not(:last-child)').map{|opt| [opt[:value], opt.text]}.each do |col_c, col_n|
      doc = Nokogiri::HTML(post(hidden, scriptmanager: "TabContainer1$TabPanel2$UpdatePanel1|TabContainer1$TabPanel2$lstcollege1", clientstate: "1", college1: col_c, eventtarget: "TabContainer1$TabPanel2$lstcollege1", btnQuery: nil))

      doc.css('select[name="TabContainer1$TabPanel2$lstDept1"] option').map{|opt| [opt[:value], opt.text]}.each do |dept_c, dept_n|
        doc = Nokogiri::HTML(post(hidden, clientstate: "1", college1: col_c, dept1_c: dept_c))
        course_temp(doc)
      end
    end

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)
    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    # 研究所課程
    doc.css('select[name="TabContainer1$TabPanel3$lstcollege2"] option:not(:last-child)').map{|opt| [opt[:value], opt.text]}.each do |col_c, col_n|
      doc = Nokogiri::HTML(post(hidden, scriptmanager: "TabContainer1$TabPanel3$UpdatePanel2|TabContainer1$TabPanel3$lstcollege2", clientstate: "2", college1: col_c, eventtarget: "TabContainer1$TabPanel3$lstcollege2", btnQuery: nil))

      doc.css('select[name="TabContainer1$TabPanel3$lstDept2"] option').map{|opt| [opt[:value], opt.text]}.each do |dept_c, dept_n|
        doc = Nokogiri::HTML(post(hidden, clientstate: "2", college1: col_c, dept1_c: dept_c))
        course_temp(doc)
      end
    end

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(r)
    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    # 其他課程
    (1..2).each do |t|
      doc = Nokogiri::HTML(post(hidden, clientstate: "3", other: "rbOption4_#{t}"))
      course_temp(doc)
    end

    @courses
  end
  # binding.pry

  def post(hidden, scriptmanager: "ScriptManager1|btnQuery", clientstate: "0", college1: "1", dept1_c: "1200", college2: "1", dept2_c: "1204", other: nil, eventtarget: nil, btnQuery: "查詢")
    r = RestClient.post(@query_url, hidden.merge({
      "ScriptManager1" => scriptmanager, 
      "TabContainer1_ClientState" => "{\"ActiveTabIndex\":#{clientstate},\"TabState\":[true,true,true,true,true,true]}",
      "lstacade_session" => "#{@year - 1911}#{@term}",
      "TabContainer1$TabPanel1$rbcom_dn" => "-9",
      "TabContainer1$TabPanel1$gCom" => "rbCom1",
      "TabContainer1$TabPanel2$lstcollege1" => college1,
      "TabContainer1$TabPanel2$lstDept1" => dept1_c,
      "TabContainer1$TabPanel2$lstgrade" => "0",
      "TabContainer1$TabPanel2$lstchoice" => "-1",
      "TabContainer1$TabPanel3$lstcollege2" => college2,
      "TabContainer1$TabPanel3$lstDept2" => dept2_c,
      "TabContainer1$TabPanel4$Gother" => other,
      "TabContainer1$TabPanel5$Gteacher" => "rbTeacher1",
      "TabContainer1$TabPanel5$lstCollege3" => "0",
      "TabContainer1$TabPanel5$lstDept3" => "06",
      "TabContainer1$TabPanel5$lstTeacher" => "06006",
      "TabContainer1$TabPanel5$txtTeacher" => "",
      "Gweekly" => "rbWeekly1",
      "Gsection" => "rbSection1",
      "__EVENTTARGET" => eventtarget,
      "__ASYNCPOST" => "true",
      "btnQuery" => btnQuery,
      }), {"User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/44.0.2403.89 Chrome/44.0.2403.89 Safari/537.36"})
  end

  def course_temp(doc)
    doc.css('tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
      data = tr.css('td').map{|td| td.text}
      syllabus_url = tr.css('a').map{|a| a[:onclick]}[0].split('\'')[1]

      course_days, course_periods, course_locations = [], [], []
      (0..data[13].length - 1).each do |t|
        course_days << data[13][t]
        course_periods << PERIODS[data[14][t]]
        course_locations << data[15]
      end

      course = {
        year: @year,    # 西元年
        term: @term,    # 學期 (第一學期=1，第二學期=2)
        name: data[5].scan(/\S+/)[0],    # 課程名稱
        lecturer: data[6],    # 授課教師
        credits: data[12].to_i,    # 學分數
        code: "#{@year}-#{@term}-#{data[0]}-?(#{data[4]})?",
        # general_code: data[4],    # 選課代碼
        url: syllabus_url,    # 課程大綱之類的連結
        required: data[11].include?('必'),    # 必修或選修
        department: data[2],    # 開課系所
        # department_code: data[1],
        # note: data[18],
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

# crawler = NutnCourseCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
