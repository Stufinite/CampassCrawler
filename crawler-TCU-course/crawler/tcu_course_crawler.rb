require 'crawler_rocks'
require 'json'
require 'iconv'
require 'pry'

class TzuChiUniversityCrawler

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year-1911
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'https://sap.tcu.edu.tw/cosintro/qry_smtrcos.asp'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []

    r = RestClient.get(@query_url)
    doc = Nokogiri::HTML(@ic.iconv(r))

    doc.css('select[name="cos_dept"] option').map{|opt| [opt[:value], opt.text]}.each do |dept_c, dept_n|

      r = RestClient.post("https://sap.tcu.edu.tw/cosintro/qry_smtrcos_list.asp", {
        "cos_smtr" => "#{@year}#{@term}",
        "qrytype" => "1",
        "cos_dept" => dept_c,
        "cos_year" => "%",
        # "tchname" => "",
        # "day1" => "",
        # "times" => "",
        # "cosname" => "",
        # "tchname2" => "",
        })
      doc = Nokogiri::HTML(@ic.iconv(r))

      doc.css('table tr[bgcolor="White"]').map{|tr| tr}.each do |tr|
        data = tr.css('td:not(:last-child)').map{|td| td.text}
        # data[9] = tr.css('td:last-child')

        time_period_regex = /[星][期](?<day>\d)[第](?<period>\d+\～?\d?\d?)/
        course_time_location = Hash[ data[8].scan(time_period_regex) ]

        # 把 course_time_location 轉成資料庫可以儲存的格式
        course_days, course_periods, course_locations = [], [], []
        course_time_location.each do |k, v|
          for i in v.split('～')[0].to_i..v.split('～')[1].to_i
            course_days << k[0].to_i
            course_periods << i    # 1~12
            course_locations << data[7]
          end
        end

        course = {
          year: @year + 1911,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[3].split('開課教師：')[0],    # 課程名稱
          lecturer: data[3].split('開課教師：')[1],    # 授課教師
          credits: data[5].to_i,    # 學分數
          code: "#{@year + 1911}-#{@term}-#{data[0]}-?(#{data[2]})?",
          # general_code: data[2],    # 選課代碼
          # url: data[9],    # 課程大綱之類的連結(抓下來的是HTML語法，網頁要用POST的才能顯示)
          required: data[6].include?('必'),    # 必修或選修
          department: dept_n + data[4],    # 開課系所
          # department_code: dept_c,
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

# crawler = TzuChiUniversityCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
