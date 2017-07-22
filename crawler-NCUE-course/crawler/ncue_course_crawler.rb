require 'crawler_rocks'
require 'json'
require 'iconv'
require 'pry'

class NcueCourseCrawler

    DAYS = {
      "一" => 1,
      "二" => 2,
      "三" => 3,
      "四" => 4,
      "五" => 5,
      "六" => 6,
      "日" => 7,
    }

  def initialize  year: nil, term: nil, update_progress: nil, after_each: nil # initialize 94建構子
    @year = year
    @term = term
    @query_url = "http://webap0.ncue.edu.tw/deanv2/other/ob010"
    # @ic = Iconv.new('utf-8//translit//IGNORE', 'big-5')
    #@result_url = "https://web085003.adm.ncyu.edu.tw/pub_depta2.aspx"
    # 這邊是因為嘉義大學的結果是另一個網頁
    @post_url = "http://webap0.ncue.edu.tw/DEANV2/Other/OB010"

    @after_each_proc = after_each
    @update_progress_proc = update_progress
  end

  def courses
    @courses = []

    # start write your crawler here:
    r = RestClient.get @query_url
    doc = Nokogiri::HTML(r)

    # doc = Nokogiri::HTML(@ic.iconv(r))

    # doc.css('select[name="WebDep67"] option')
    # doc.css('select[name="WebDep67"] option')[0][:value]
    # doc.css('select[name="WebDep67"] option')[0].text

    # doc.css('select[name="WebDep67"] option').map{|opt| opt[:value]}

    # h = {"abc"=>123, 0=>"asdf", :symbol=>"asdf"}
    # h.each { |k, v| puts "key is #{k}, value is #{v}" }

    # (0..4).each {|i| puts i}
    # [1, 2, 3, 4, 5].each do |i|
    #   puts i
    # end

    # {"a" => 1}
    # {:a => 1}
    # {a: 1}

    post_dept_values = doc.css('select[name="sel_cls_id"] option').map{|opt| opt[:value] }[1..-1]
    dept_names = doc.css('select[name="sel_cls_id"] option').map{|opt| opt.text }[1..-1] #也要存資料用的，也可以當辨識

    post_dept_values.each_with_index do |dept_value, index|
      print "#{index+1} / #{post_dept_values.count}\n"
      r = RestClient.post(@post_url, {
        "sel_cls_branch" => "D",
        "sel_yms_year" => "104",
        "sel_yms_smester" => "1",
        "sel_cls_id" => dept_value,
        "X-Requested-With" => "XMLHttpRequest"
      })
      department = dept_names[index]
      doc = Nokogiri::HTML(r)

      # binding.pry

      doc.css('tr')[1..-1].each do |row|
        columns = row.css('td')

        period_raw_data = columns[10].text.strip
        reg = /\((?<day>[一二三四五六日])\) (?<s>\d{2})(\-(?<e>\d{2}))? (?<loc>.+)/
        course_days = []
        course_periods = []
        course_locations = []

        # m = period_raw_data.match(reg)
        # if !!m
        #   m[:day]
        # end
          period_raw_data.match(reg) do |m|
            
            day = DAYS[m[:day]]

            start_period = m[:s].to_i
            end_period = m[:e].to_i
            end_period = start_period if end_period == 0

            location = m[:loc]

  # begin
            (start_period..end_period).each do |period|
              course_days << day
              course_periods << period
              course_locations << location
            end
  # rescue Exception => e
  #   binding.pry
  # end
          end
          

        course = {
          department: columns[2].text,
          name: columns[3].text,
          year: @year,
          term: @term,
          code: "#{@year}-#{@term}-#{columns[1].text}", # #{這個裡面放變數}
          credits:columns[8].text,
          required: columns[6].text.include?('必'),
          lecturer:columns[9].text.strip,
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
      end # end each row

      # table = doc.css('table[border="1"][align="center"][cellpadding="1"][cellspacing="0"][width="99%"]')[0]

      # rows = table.css('tr:not(:first-child)')
      # rows.each do |row|
      #   table_datas = row.css('td')

      #   course = {
      #     department_code: table_datas[2].text,
      #     # name: aaa,
      #     # code: aaa,
      #   }

      #   @courses << course
      # end
      # File.write("temp/#{dept_value}.html", r)
    end # end each dept_values

    # binding.pry
    # puts "hello"

    @courses
  end # end courses method

  # def current_year
  #   (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
  # end

  # def current_term
  #   (Time.now.month.between?(2, 7) ? 2 : 1)
  # end
end

# crawler = NcueCourseCrawler.new(year: 2015, term: 1)
# File.write('ncue_courses.json', JSON.pretty_generate(crawler.courses()))
