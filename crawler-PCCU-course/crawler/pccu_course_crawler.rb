require 'capybara'
# require 'capybara/poltergeist'
require 'capybara-webkit'
require 'pry'
require 'nokogiri'
require 'uri'
require 'rest-client'

require 'thread'
require 'thwait'

class PccuCourseCrawler
  include Capybara::DSL

  PERIODS = {
    "M1" => 1,
    "M2" => 2,
    "01" => 3,
    "02" => 4,
    "03" => 5,
    "04" => 6,
    "05" => 7,
    "06" => 8,
    "07" => 9,
    "08" => 10,
    "09" => 11,
    "10" => 12,
    "11" => 13,
    "12" => 14,
    "13" => 15,
    "14" => 16,
    "15" => 17,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @base_url = "https://ap1.pccu.edu.tw"

    # Capybara.register_driver :poltergeist do |app|
    #   Capybara::Poltergeist::Driver.new(app,  {
    #     js_errors: false,
    #     timeout: 10000,
    #     ignore_ssl_errors: true,
    #     # debug: true,
    #     phantomjs_options: [
    #       '--load-images=no',
    #       '--ignore-ssl-errors=yes',
    #       '--ssl-protocol=any'],
    #   })
    # end

    Capybara.javascript_driver = :selenium
    Capybara.current_driver = :selenium
  end

  def courses
    @courses = []

    dept = 1
    loop do
    # (1..4).each do |grade|
    # (1..@dept1_count-1).each do |dept|
    # (1..dept_count_hash[dept]-1).each do |dept2|
      visit "https://ap1.pccu.edu.tw/index.asp"
      click_on '課程/課表查詢'

      sleep 2
      page.switch_to_window(page.windows.last)
      page.windows.first.close


      # url = URI.decode current_url
      # match = url.match(/ApGUID=\{(?<guid>.+)\}/)
      # guid = match[:guid]

      # visit URI.encode "https://ap1.pccu.edu.tw/newAp/frame/apMainFrameSet.asp?ApGUID={#{guid}}"
      # sleep 5
      # binding.pry

      frame = first 'iframe'
      within_frame frame do
        within_frame 'downFrame' do
          within_frame 'rightFrame' do
            sleep 2
            first('#scdfAcadmYear').set(@year-1911)
            first("#scdfTerm option[value=\"#{@term}\"]").select_option

            @dept1_count ||= all('select[name="scdfColDep1"] option').count
            # first("select[name=\"scdfFormClassSect\"] option[value=\"#{grade}\"]").select_option
            all('select[name="scdfColDep1"] option')[dept].select_option
            # all('select[name="scdfColDep2"] option')[dept2].select_option

            click_button '查詢'

            page_count = 1
            all_page = nil;

            begin
              while true
                all_page ||= all('font.pubImportantMsg')[1].text.to_i

                print " #{page_count} / #{all_page}\n"
                # File.open("1031/#{grade}-#{page_count}.html", 'w') { |f| f.write(html) }
                parse_course( Nokogiri::HTML(html) )

                click_on '下20筆'

                page_count += 1
              end # end while
            rescue Exception => e
            end # end begin

          end # end rightFrame
        end # end downframe
      end # end iframe

      dept += 1
      break if dept >= @dept1_count - 1
    end # end loop

    @courses
  end

  def parse_course doc
    threads = []
    doc.css('table.pubTable tr:not(:first-child)').each do |row|
      threads << Thread.new do
        datas = row.css('td')

        datas[3].search('br').each {|d| d.replace("\n")}
        code_raw = datas[3].text.split("\n")
        general_code = code_raw[0]
        group = code_raw[1]
        class_code = datas[2].text.strip

        dep_raws = datas[1] && datas[1].text.split(' ')
        department = dep_raws[0]
        department_code = dep_raws[1]

        name = datas[5] && datas[5].text.strip.gsub(/\s+/, ' ')

        code = "#{@year}-#{@term}-#{general_code}-#{group}-#{class_code}-#{department_code}"

        url = datas[5] && datas[5].css('a') && datas[5].css('a')[0] && datas[5].css('a')[0][:href]

        course_days = []
        course_periods = []
        course_locations = []
        datas[8] && datas[8].text.match(/(?<d>\d)\：(?<p>.{2}\-.{2})\s+(?<loc>.\s+\d+)/) do |m|
          m[:p] && ps = m[:p].split('-')
          from = PERIODS[ps[0]]
          to = PERIODS[ps[1]]
          (from..to).each do |period|
            course_days << m[:d].to_i
            course_periods << period
            course_locations << m[:loc].gsub(/\s+/, ' ')
          end
        end


        course = {
          year: @year,
          term: @term,
          general_code: general_code,
          grade: datas[2] && datas[2].text.to_i,
          code: code,
          department: department,
          department_code: department_code,
          name: "(#{group}) #{name} [#{department}]",
          url: "#{@base_url}#{url}",
          credits: datas[6] && datas[6].text.to_i,
          lecturer: datas[7] && datas[7].text.strip,
          required: datas[9] && datas[9].text.include?('必'),
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
      end # end new Thread
    end # end each row

    ThreadsWait.all_waits(*threads)
  end

  def current_year
    (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
  end

  def current_term
    (Time.now.month.between?(2, 7) ? 2 : 1)
  end
end

# cc = PccuCourseCrawler.new(year: 2015, term: 1)
# File.write('1041_pccu_courses.json', JSON.pretty_generate(cc.courses))
