require 'capybara'
require 'capybara/poltergeist'

require 'json'
require 'pry'

require 'thread'
require 'thwait'

require 'crawler_rocks'

class YuntechCourseCrawler
  include Capybara::DSL

  PERIODS = {
    "W" => 1,
    "X" => 2,
    "A" => 3,
    "B" => 4,
    "C" => 5,
    "D" => 6,
    "Y" => 7,
    "E" => 8,
    "F" => 9,
    "G" => 10,
    "H" => 11,
    "Z" => 12,
    "I" => 13,
    "J" => 14,
    "K" => 15,
    "L" => 16,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "https://webapp.yuntech.edu.tw/WebNewCAS/Course/QueryCour.aspx?lang=zh-TW"
    @base_url = "https://webapp.yuntech.edu.tw"

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app,  {
        js_errors: false,
        timeout: 300,
        ignore_ssl_errors: true,
        # debug: true
      })
    end

    Capybara.javascript_driver = :poltergeist
    Capybara.current_driver = :poltergeist
  end

  def courses
    @courses = []
    visit @query_url

    year_term = "#{@year-1911}#{@term}"

    first("select[name=\"ctl00$ContentPlaceHolder1$AcadSeme\"] option[value=\"#{year_term}\"]").select_option

    coll_selector = 'select[name="ctl00$ContentPlaceHolder1$College"] option:not(:first-child)'
    dept_selector = 'select[name="ctl00$ContentPlaceHolder1$DeptCode"] option:not(:first-child)'
    coll_count = all(coll_selector).count

    # select each dep gathering post data
    (0...coll_count).each do |coll_index|
      visit @query_url

      first("select[name=\"ctl00$ContentPlaceHolder1$AcadSeme\"] option[value=\"#{year_term}\"]").select_option

      college_opt = all(coll_selector)[coll_index]
      college = college_opt.text
      college_opt.select_option
      sleep 1

      dept_count = all(dept_selector).count

      (0...dept_count).each do |dept_index|
        visit @query_url
        first("select[name=\"ctl00$ContentPlaceHolder1$AcadSeme\"] option[value=\"#{year_term}\"]").select_option

        all(coll_selector)[coll_index].select_option

        sleep 1
        dep_option = all(dept_selector)[dept_index]
        dep_option.select_option

        department = dep_option.text
        department_code = dep_option[:value]
        print "#{department}: "
        click_on '執行查詢'

        # parse each page
        total_page = find('#ctl00_ContentPlaceHolder1_PageControl1_TotalPage').text.to_i
        (1..total_page).each do |page_count|
          print "#{page_count}, "
          find("select[name=\"ctl00$ContentPlaceHolder1$PageControl1$Pages\"] option[value=\"#{page_count}\"]").select_option
          # sleep longer if crawl error
          sleep 2

          @courses.concat parse_course(html, department, department_code)
        end # end each page
        puts
      end # all dept option do
    end # all college option do

    page.driver.quit

    @threads = []
    @courses.each do |course|
      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < ( (ENV['MAX_THREADS'] && ENV['MAX_THREADS'].to_i) || 30)
      )
      @threads << Thread.new {
        @after_each_proc.call(course: course) if @after_each_proc
      }
    end
    ThreadsWait.all_waits(*@threads)

    @courses
  end # end courses method

  def parse_course html, dept_n, dept_c
    doc = Nokogiri::HTML(html)

    rows = doc.css('tr.GridView_AlternatingRow') + doc.css('tr.GridView_Row')
    rows.map do |row|
      datas = row.css('td')

      time = datas[7] && datas[7].text.strip
      course_days = []
      course_periods = []
      course_locations = []
      m = time && time.match(/(?<d>\d)\-(?<p>.+)\/(?<loc>.+)/)
      if !!m
        m[:p].split("").each do |period|
          course_days << m[:d].to_i
          course_periods << PERIODS[period]
          course_locations << m[:loc]
        end
      end

      serial_no = datas[0] && datas[0].text.strip
      curriculum_no = datas[1] && datas[1].text.strip
      code = "#{serial_no}-#{curriculum_no}"

      url = nil
      href = datas[2] && datas[2].css('a')[0] && datas[2].css('a')[0][:href]
      href && href.match(/javascript\:openwindow\(\'(?<href>.+)\'\)/) do |m|
        url = "#{@base_url}#{m[:href]}"
      end

      {
        year: @year,
        term: @term,
        code: code,
        general_code: curriculum_no,
        department: dept_n,
        department_code: dept_c,
        name: datas[2] && datas[2].text.strip.gsub(/\s+/, ' '),
        lecturer: datas[8] && datas[8].text.strip,
        url: url,
        class_id: datas[3] && datas[3].text.strip,
        team: datas[4] && datas[4].text.strip,
        required: datas[5] && datas[5].text.strip.gsub(/\s+/, ' ').include?('必'),
        credits: datas[6] && datas[6].text.strip.split('-').last.to_i,
        class_member: datas[9] && datas[9].text.strip,
        note: datas[11] && datas[11].text.strip.gsub(/\s+/, ' '),
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
    end
  end

  def current_year
    (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
  end

  def current_term
    (Time.now.month.between?(2, 7) ? 2 : 1)
  end

end

# cc = YuntechCourseCrawler.new(year: 2014, term: 1)
# File.write('1031_yuntech_courses.json', JSON.pretty_generate(cc.courses))
