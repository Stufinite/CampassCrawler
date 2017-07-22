require 'crawler_rocks'
require 'json'
require 'iconv'
require 'pry'
require 'httpclient'
require 'uri'

class NkuhtCourseCrawler

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    # @query_url = 'http://classic.nkuht.edu.tw/PUB/PubCur.asp'
    @query_url = 'http://classic.nkuht.edu.tw/PUB/'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []

    r = HTTPClient.get(@query_url + "GetOpClass.asp?Years=#{@year - 1911}&Term=#{@term}").body
    doc = Nokogiri::HTML(@ic.iconv(r))

    doc.css('a').map{|a| a[:onclick]}.each do |dept|

      r = HTTPClient.get(@query_url + "CurDataList.asp?Years=#{@year - 1911}&Term=#{@term}&TeamNo=&DeptName=#{URI.escape(Iconv.conv('Big5', 'utf-8', dept.split('\'')[5]))}&OpClass=#{dept.split('\'')[9]}").body
      doc = Nokogiri::HTML(@ic.iconv(r))

      doc.css('tr:nth-child(n+4)').map{|tr| tr}.each do |tr|
        data = tr.css('td').map{|td| td.text}
        syllabus_url = @query_url + "Sel_Teaching.asp?Years=#{@year - 1911}&Term=#{@term}&EntryYear=&DeptName=#{URI.escape(Iconv.conv('Big5', 'utf-8', dept.split('\'')[5]))}&TeamNo=&OpClass=#{dept.split('\'')[9]}&Op_Class=#{dept.split('\'')[9]}&Serial=#{tr.css('a').map{|a| a[:onclick]}[0].split('\'')[7]}&Cos_ID=#{data[1]}&PageNo="

        time_period_regex = /(?<d_p>([1-7]\d\d\(?\S?\)?[\s\ ])+)\/\ (?<loc>(\S+\s?)+)?/
        course_time_location = data[4].scan(time_period_regex)

        course_days, course_periods, course_locations = [], [], []
        course_time_location.each do |d_p, loc|
          next if d_p == nil
          d_p.scan(/(?<day>[1-7])(?<period>\d\d)/).each do |day, period|
            course_days << day.to_i
            course_periods << period.to_i
            course_locations << loc
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[2],    # 課程名稱
          lecturer: data[3],    # 授課教師
          credits: data[5].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{data[0]}-?(#{data[1]})?",
          # general_code: data[1],    # 選課代碼
          url: syllabus_url,    # 課程大綱之類的連結(如果有的話)
          required: data[8].include?('必'),    # 必修或選修
          department: dept.split('\'')[5],    # 開課系所
          # department_code: dept.split('\'')[9],
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

# crawler = NkuhtCourseCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
