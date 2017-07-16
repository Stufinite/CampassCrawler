require 'crawler_rocks'
require 'iconv'
require 'json'
require 'pry'
require 'capybara'
require 'capybara/poltergeist'

class NutcCourseCrawler
  include Capybara::DSL

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @year = current_year
    @query_url = "http://academic.nutc.edu.tw/curriculum/show_subject/show_subject_form.asp?show_vol=#{@term}"

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
    click_on '　下　一　步　'
    option_count = all('select[name="show_select1"] option').count

    begin
      option_count.times do |i|
        visit @query_url
        click_on '　下　一　步　'

        sleep 2
        opt = all('select[name="show_select1"] option')[i]
        opt.select_option
        puts opt.text
        click_on '開始查詢資料'

        # parse table
        doc = Nokogiri.HTML(html)
        doc.css('table tr:not(:first-child)').each do |row|
          datas = row.css('td')


          # parse time table
          timetable_url = datas[4] && !datas[4].css('a').empty? && datas[4].css('a')[0][:href]
          timetable_url = "http://academic.nutc.edu.tw/curriculum/show_subject/#{timetable_url}"

          course_days = []
          course_periods = []
          course_locations = []
          execute_script("window.open(\"#{timetable_url}\")")
          within_window windows.last do
            timetable = Nokogiri::HTML(html)
            table = !timetable.css('#Layer1 > table').empty? && timetable.css('#Layer1 > table')[0]
            if table
              table.css('tr:not(:first-child)').each_with_index do |row, p|
                row.css('td:nth-child(n+3)').each_with_index do |data, d|
                  if not data.text.gsub(/[\s|　]+/, '').empty?
                    location = data.css('font[color="#FF0000"]').text
                    course_days << (d+1).to_s
                    course_periods << (p+1).to_s
                    course_locations << location
                  end
                end
              end
            end
          end
          windows.last.close

          # r = RestClient.get timetable_url

          url = datas[11] && !datas[11].css('a').empty? && datas[11].css('a')[0][:href]
          url = url && "http://academic.nutc.edu.tw/#{url[7..-1]}"

          begin
            code = CGI.parse(URI(url).query)["flow_no"][0]
          rescue Exception => e
            code = nil
          end

          department = datas[1] && datas[1].text.strip
          next if department.nil?

          @courses << {
            year: @year,
            term: @term,
            department: department,
            # semester: datas[2] && datas[2].text.strip,
            code: code,
            required: datas[3] && datas[3].text.strip.include?('必'),
            name: datas[4] && datas[4].text.strip,
            lecturer: datas[5] && datas[5].text.strip,
            credits: datas[6] && datas[6].text.to_i,
            url: url,
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

        evaluate_script('window.history.back()')
      end
    rescue Exception => e
      binding.pry
    end
    @courses
  end

  def current_year
    (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
  end

  def current_term
    (Time.now.month.between?(2, 7) ? 2 : 1)
  end
end

cc = NutcCourseCrawler.new(year: 2014, term: 1)
File.write('courses.json', JSON.pretty_generate(cc.courses))
