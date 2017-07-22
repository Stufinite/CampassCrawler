require 'crawler_rocks'
require 'json'
require 'iconv'
require 'pry'

class NationalUniversityOfKaohsiungCrawler

  PERIODS = {
    "X" => nil,
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "Y" => 5,
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

    @query_url = 'http://course.nuk.edu.tw/QueryCourse/'
    @ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
  end

  def courses
    @courses = []

    r = RestClient.post(@query_url + "QueryCourse.asp", {
      "OpenYear" => @year - 1911,
      "Helf" => @term,
      })
    doc = Nokogiri::HTML(@ic.iconv(r))

    Hash[doc.css('select[name="Pclass"] option:not(:first-child)').map{|opt| [opt[:value], opt.text]}].each do |fac_c, fac_n|

      r = RestClient.post(@query_url + "QueryCourse.asp", {
        "OpenYear" => @year - 1911,
        "Helf" => @term,
        "Pclass" => fac_c,
        })
      doc = Nokogiri::HTML(@ic.iconv(r))

      Hash[doc.css('select[name="Sclass"] option:not(:first-child)').map{|opt| [opt[:value], opt.text]}].each do |dep_c, dep_n|

        r = RestClient.post(@query_url + "QueryCourse.asp", {
          "OpenYear" => @year - 1911,
          "Helf" => @term,
          "Pclass" => fac_c,
          "Sclass" => dep_c,
          })
        doc = Nokogiri::HTML(@ic.iconv(r))

        hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

        r = RestClient.post(@query_url + "QueryResult.asp", hidden.merge({
          "OpenYear" => @year - 1911,
          "Helf" => @term,
          "Pclass" => fac_c,
          "Sclass" => dep_c,
          }) )
        doc = Nokogiri::HTML(@ic.iconv(r))

        doc.css('tr[align = "center"]').map{|tr| tr}.each do |tr|
          data = tr.css('td').map{|td| td.text}
          syllabus_url = @query_url + tr.css('td a').map{|a| a[:href]}[0]

          course_days, course_periods, course_locations = [], [], []
          {1 => data[13],2 => data[14],3 => data[15],4 => data[16],5 => data[17],6 => data[18],7 => data[19]}.each do |day, periods|
            if periods != nil
              periods.scan(/(?<period>\w+)/).each do |p|
                next if p[0] == "X"
                course_days << day
                course_periods << PERIODS[p[0]]
                course_locations << data[12]
              end
            end
          end

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[4].scan(/\S+/)[0],    # 課程名稱
            lecturer: data[11],    # 授課教師
            credits: data[5].to_i,    # 學分數
            code: "#{@year}-#{@term}-#{data[0]}-?(#{data[1]})?",
            # general_code: data[1],    # 選課代碼
            url: syllabus_url,    # 課程大綱之類的連結(如果有的話)
            required: data[6].include?('必'),    # 必修或選修
            department: dep_n,    # 開課系所
            # department_code: data[0],  # 系所代碼
            # notes: data[21],  # 備註
            # limit_people: data[7],  # 限修人數
            # people: data[8],  # 選課確定
            # people_online: data[9],  # 線上人數
            # people_last: data[10],  # 餘額
            # pre_limit: data[20],  # 先修限修學程
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
    # binding.pry if dep_c == "LA"
        end
      end
    end
    @courses
  end

end

# crawler = NationalUniversityOfKaohsiungCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
