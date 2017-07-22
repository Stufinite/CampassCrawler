require 'crawler_rocks'
require 'json'
require 'pry'

require 'thread'
require 'thwait'

class KuasCourseCrawler

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
    "A" => 6,
    "5" => 7,
    "6" => 8,
    "7" => 9,
    "8" => 10,
    "B" => 11,
    "11" => 12,
    "12" => 13,
    "13" => 14,
    "14" => 15,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil, params: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://140.127.113.224/kuas/"
  end

  def courses detail: false
    @courses = []
    @threads = []

    r = RestClient.post(@query_url + "perchk.jsp", {"uid" => "guest", "pwd" => "123"})
    cookies = r.cookies

    r = RestClient.get(@query_url + "f_index.html", cookies: cookies)
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = RestClient.post(@query_url + "fnc.jsp", hidden.merge({"fncid" => "AG304"}), cookies: cookies )
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = RestClient.post(@query_url + "ag_pro/ag304.jsp", hidden.merge({}), cookies: cookies )

    r = RestClient.get(@query_url + "ag_pro/ag304_01.jsp", cookies: cookies )
    doc = Nokogiri::HTML(r)

    doc.css('select[name="dgr_id"] option').map{|opt| [opt[:value], opt.text]}.each do |dgr_c, dgr_n|
      r = RestClient.post(@query_url + "ag_pro/ag304_02.jsp", {
        "yms_yms" => "#{@year - 1911}##{@term}",
        "dgr_id" => dgr_c,
        "unit_serch" => "查 詢",
        # "ls_dvs_id" => "",
        "ls_yn" => "N",
        }, cookies: cookies )
      doc = Nokogiri::HTML(r)

      doc.css('table tr:nth-child(n+2) div').map{|td| [td[:onclick].scan(/\'(\w+)/)[0][0], td.text]}.each do |dep_c, dep_n|
        r = RestClient.post(@query_url + "ag_pro/ag304_03.jsp", {
          "arg01" => @year - 1911,
          "arg02" => @term,
          "arg" => dep_c,
          }, cookies: cookies )
        doc = Nokogiri::HTML(r)

        doc.css('table[border="1"]:nth-child(2) tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
          data = tr.css('td:not(:last-child)').map{|td| td.text}
          syllabus_url = "http://140.127.113.224/kuas/ag_pro/ag451.jsp?year=#{@year - 1911}&sms=#{@term}&dvs=all&dgr=all&unt=all&cls=#{dep_c}&sub=#{tr.css('td:last-child').map{|a| a[:onclick]}[0].scan(/\,(\w+)\./)[0][0]}&empidno=all"

          time_period_regex = /(?<day>[一二三四五六日])\)(?<period>(\w+)\-?\,?(\w+)?\,?\-?(\w+)?\-?(\w+)?)/
          course_time_location = data[7].scan(time_period_regex).map{|day, period| [day, period]}

          course_days, course_periods, course_locations = [], [], []
          p1, p2, p3, p4 = nil, nil, nil, nil
          course_time_location.each do |day, period|
            if period.include?(',')
              if period.split(',')[0].include?('-')
                p1, p2 = period.scan(/\w+/)[0], period.scan(/\w+/)[1]
              else
                p1 = p2 = period.scan(/\w+/)[0]
              end
              if period.split(',')[1].include?('-')
                p3, p4 = period.scan(/\w+/)[-2], period.scan(/\w+/)[-1]
              else
                p3 = p4 = period.scan(/\w+/)[-1]
              end
            else
              if period.include?('-')
                p1, p2 = period.scan(/\w+/)[0], period.scan(/\w+/)[1]
              else
                p1 = p2 = period.scan(/\w+/)[0]
              end
            end
            if p1 != nil
              (PERIODS[p1]..PERIODS[p2]).each do |p|
                course_days << DAYS[day]
                course_periods << p
                course_locations << data[9]
              end
            end
            if p3 != nil
              (PERIODS[p3]..PERIODS[p4]).each do |p|
                course_days << DAYS[day]
                course_periods << p
                course_locations << data[9]
              end
            end
          end

          course = {
            year: @year,    # 西元年
            term: @term,    # 學期 (第一學期=1，第二學期=2)
            name: data[1],    # 課程名稱
            lecturer: data[8],    # 授課教師
            credits: data[3][0].to_i,    # 學分數
            code: "#{@year}-#{@term}-#{dep_c}-#{data[0].scan(/\w+/)[0]}",
            # general_code: data[0],    # 選課代碼
            general_code: data[0].scan(/\w+/)[0],
            url: syllabus_url,    # 課程大綱之類的連結(如果有的話)
            required: data[5].include?('必'),    # 必修或選修
            department: dep_n,    # 開課系所
            department_code: dep_c,
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

          sleep(1) until (
            @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
            @threads.count < ( (ENV['MAX_THREADS'] && ENV['MAX_THREADS'].to_i) || 30)
          )
          @threads << Thread.new do
            @after_each_proc.call(course: course) if @after_each_proc
          end

          @courses << course
    # binding.pry if dep_c == "UE233311"
        end
      end
    end
    ThreadsWait.all_waits(*@threads)

    @courses
  end
end

# crawler = KuasCourseCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
