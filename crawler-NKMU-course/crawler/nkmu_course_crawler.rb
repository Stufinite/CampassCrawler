require 'nokogiri'
require 'httpclient'
require 'pry'
require 'json'

require 'thread'
require 'thwait'


class NkmuCourseCrawler

  DAYS={
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6
  }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil
    @year = year
    @term = term
    @update_progress = update_progress
    @after_each = after_each
  end

  def courses
    @courses=[]
    @threads=[]

    res1 = clnt.post("http://info.nkmu.edu.tw/nkmu/perchk.jsp", {
      uid: 'guest',
      pwd:  '123',
      sys_name: 'webweb'
    })
    
    res2 = clnt.post "http://info.nkmu.edu.tw/nkmu/fnc.jsp", {
      fncid: 'AG202'
    }

    res3 = clnt.post "http://info.nkmu.edu.tw/nkmu/ag_pro/ag202.jsp?", {
      'arg01': @year-1911,
      'arg02': @term,
      'arg03': 'guest',
      'arg04': '',
      'arg05': '',
      'arg06': '',      
      'fncid': 'AG202'
    }

    res4 = clnt.post "http://info.nkmu.edu.tw/nkmu/ag_pro/ag202.jsp?", {
      'yms_yms': "#{@year-1911}\##{@term}",
      'dgr_id': '%',
      'unt_id': '%',
      'clyear': '',
      'sub_name': '',
      'teacher': '',
      'week': '%',
      'period': '%',
      'yms_year': @year-1911,
      'yms_sms': @term,
      'reading': 'reading'
    }

    @courses_list = Nokogiri::HTML(res4.body)
    
    @courses_list_trs=@courses_list.css('table').last.css('tr')[2..-1]

    @courses_list_trs.each_with_index do | row, index|
      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < 20 ;
      )

      @threads << Thread.new do
        table_data = row.css('td')

        #Analyize data of tr
        course_divisional = table_data[0].text.strip
        course_department  = table_data[1].text.strip
        course_class = table_data[2].text.strip
        course_general_code = table_data[3].text.strip
        course_name = table_data[4].text.strip
        course_credits = table_data[5].text.strip.to_i
        course_hours = table_data[6].text.strip.to_i
        course_required = table_data[7].text.strip
        course_lecturer = table_data[8].text.strip
        course_time=table_data[11].text.strip

        #Analyize string of course_time.
        course_day_period=[]
        course_time.scan(/\(.\)[^\(]+/).each do |i|
          course_day_period << i.match(/\((?<day>.)\)(?<period>.*)/)
        end

        course_locations=[]
        course_days = []
        course_periods = []
        course_day_period.each do |i|
          (i[:period].split("-").first..i[:period].split("-").last).each do |k|
            course_days << DAYS[i[:day]]
            course_periods << k
            course_locations << table_data[9].text.strip
          end
        end

        course = {
          :year => @year,    # 西元年
          :term => @term,    # 學期 (第一學期=1，第二學期=2)
          :name => course_name,    # 課程名稱
          :lecturer => course_lecturer,    # 授課教師
          :credits => course_credits,    # 學分數
          :code => "#{@year}-#{@term}-#{course_general_code}",
          :general_code => course_general_code,    # 選課代碼
          :required => course_required.include?('必'),    # 必修或選修
          :department => course_department,    # 開課系所
          
          :day_1 => course_days[0],
          :day_2 => course_days[1],
          :day_3 => course_days[2],
          :day_4 => course_days[3],
          :day_5 => course_days[4],
          :day_6 => course_days[5],
          :day_7 => course_days[6],
          :day_8 => course_days[7],
          :day_9 => course_days[8],

          :period_1 => course_periods[0].to_i,
          :period_2 => course_periods[1].to_i,
          :period_3 => course_periods[2].to_i,
          :period_4 => course_periods[3].to_i,
          :period_5 => course_periods[4].to_i,
          :period_6 => course_periods[5].to_i,
          :period_7 => course_periods[6].to_i,
          :period_8 => course_periods[7].to_i,
          :period_9 => course_periods[8].to_i,

          :location_1 => course_locations[0],
          :location_2 => course_locations[1],
          :location_3 => course_locations[2],
          :location_4 => course_locations[3],
          :location_5 => course_locations[4],
          :location_6 => course_locations[5],
          :location_7 => course_locations[6],
          :location_8 => course_locations[7],
          :location_9 => course_locations[8]
        }
        @after_each_proc.call(course: course) if @after_each_proc
        @courses << course
      end #end thread
    end #end each tr
    ThreadsWait.all_waits(*@threads)
    @courses
  end #end courses

  def clnt
    @http_client ||= HTTPClient.new
  end
end