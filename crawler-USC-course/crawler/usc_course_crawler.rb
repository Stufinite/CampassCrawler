require 'pry'
require 'crawler_rocks'
require 'rest-client'

class UscCourseCrawler
  include CrawlerRocks::DSL

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @get_url = "http://studentsystem.usc.edu.tw/CourseSystem/Top.asp"
    @result_url = "http://studentsystem.usc.edu.tw/CourseSystem/result_NewNew.asp"

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

  end

  def courses detail: false
    @courses = []

    visit @get_url


    r = RestClient.post(@result_url, {
      "optSclYer" => @year-1911,
      "optSclTrm" => @term,
      "optSLSID" => "$",
      "optDEPID" => "$",
      "optSEL" => 0,
      "optSEARCH" => "",
      "WhatCourse" => "All",
      "btnSend" => "課程搜尋"
    }, cookies: @cookies)

    # ic = Iconv.new('utf-8', r.encoding)
    # binding.pry.force_encoding('utf-8')
    @doc = Nokogiri::HTML(r.to_s.force_encoding('big5').encode('utf-8', invalid: :replace, :undef => :replace, :replace => ''))

    rows = @doc.css('tr:nth-child(n+4)')
    rows.each do |row|
      columns = row.css('td')
      begin
        match_raws = columns[9].text.strip.split('/').map {|s|
          s.match(/(?<day>[#{DAYS.keys.join}]|)\((?<periods>.+)\)(?<classroom>$|.+)/)
        }
      rescue
        next
      end

      course_days = []
      course_periods = []
      course_locations = []

      match_raws.each do |mat|
        begin
          mat["periods"].split(',').each do |period|
            course_days << DAYS[mat["day"]]
            course_periods << period.to_i
            course_locations << mat["classroom"]
          end
        rescue
        end
      end

      url = columns[3].css('a')[0]["href"] if not columns[3].css('a').empty?
      group_code = nil; group = nil; department = nil; department_code = nil;


      # if !s.valid_encoding?
      #   s = s.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
      # end
      columns[1].text.match(/\((?<gc>(?<dep_c>.{2}).{2})\)(?<gn>(?<dep_n>.{2})(?<gt>.)(?<g>.))/) do |m|
        department = m[:dep_n]
        department_code = m[:dep_c]
        group = m[:gn]
        group_code = m[:gc]
      end


      serial_no = columns[0].text.strip
      code = "#{@year}-#{@term}-#{serial_no}-#{group_code}"

      @courses << {
        serial_no: serial_no,
        name: columns[3].text.strip,
        url: "http://studentsystem.usc.edu.tw/CourseSystem/#{url}",
        required: columns[5].text.include?('必'),
        credits: Integer(columns[6].text.strip),
        hours: Integer(columns[7].text.strip),
        lecturer: columns[8].text.strip,
        department: department,
        department_code: department_code,
        group: group,
        group_code: group_code,
        code: code,
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
        note: columns[15].text.strip
      }
    end

    File.write('courses.json', JSON.pretty_generate(@courses))
    @courses
  end

  # def crawl_detail
  #   @courses = JSON.parse File.read('courses.json')
  #   progressbar = ProgressBar.create(:total => @courses.count)
  #   @courses.each do |course|
  #     progressbar.increment
  #     begin
  #       r = RestClient.get course["url"]
  #       doc = Nokogiri::HTML(r.to_s)

  #     rescue Exception => e
  #       redo
  #     end

  #     begin
  #       rows = doc.css('tr')
  #       course_title_row = doc.css('tr:contains("Materials")').last
  #       textbook_row = rows[rows.index(course_title_row) + 1]
  #       textbook_row.search('br').each {|k| k.replace("\n")}
  #       course["textbook"] = textbook_row.text.strip
  #     rescue Exception => e

  #     end

  #     begin
  #       reference_title_row = doc.css('tr:contains("References")').first
  #       reference_row = rows[reference_title_row + 3]
  #       reference_row.search('br').each {|k| k.replace("\n")}
  #       course["references"] = reference_row.text.strip
  #     rescue Exception => e

  #     end

  #   end
  # end

  private
    def current_year
      (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
    end

    def current_term
      (Time.now.month.between?(2, 7) ? 2 : 1)
    end
end

cc = UscCourseCrawler.new(year: 2014, term: 2)
cc.courses
