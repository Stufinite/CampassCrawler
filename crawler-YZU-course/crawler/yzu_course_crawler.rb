require 'crawler_rocks'
require 'json'
require 'pry'

class YzuCourseCrawler
  include CrawlerRocks::DSL

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil
    @url = "https://portal.yzu.edu.tw/cosSelect/Index.aspx?Lang=TW"

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each
  end

  def courses(detail: false)
    @courses = []


    visit @url
    @year_term_value = @doc.css('#DDL_YM option').map{|d| d[:value]}.find{|s| s.match(/(#{@year-1911}\,#{@term})(\s+)?/)}

    # click radio button
    post @url, get_view_state.merge({
      '__EVENTTARGET' => 'RadioButton2',
      'Q' => 'RadioButton2',
      'DDL_YM' => @year_term_value,
      'DDL_Dept' => 300,
      'DDL_Degree' => 1,
    })

    # submit query, may wait for a long time
    post @url, get_view_state.merge({
      'Q' => 'RadioButton2',
      'DDL_YM2' => @year_term_value,
      'Txt_Cos_Name' => ' ',
      'Button2' => '確定',
    })

    rows = @doc.css('#Table1 tr:not(:first-child)')
    rows.each_with_index do |row, index|
      next if index % 2 == 1

      datas = row.css('td')

      # beautiful css QAQ
      detail_url = "https://portal.yzu.edu.tw/cosSelect".concat datas[1].css('a')[0]["href"][1..-1]
      base_code = datas[1].text.gsub(/\s/,'-')
      course_code = "#{@year}-#{@term}-#{base_code}"
      group = datas[2].text
      course_name = datas[3].css('*')[0].text
      eng_url = "https://portal.yzu.edu.tw/cosSelect".concat datas[3].css('*')[1][:href][1..-1]

      department = nil; department_code = nil;
      group.match(/(?<dep>.+)\s.+/) {|m| department = m[:dep] }
      base_code.match(/(?<c>^[A-Z]+)/) {|m| department_code = m[:c] }

      # Flatten timetable
      course_days = []
      course_periods = []
      course_locations = []

      datas[5].search('br').each {|br| br.replace("\n")}
      datas[5].text.split("\n").each do |s|
        # 408,3424
        # 409,3428
        s.match(/(?<d>\d)(?<p>\d{2})\,(?<loc>.+)/) do |m|
          course_days << m[:d]
          course_periods << m[:p].to_i
          course_locations << m[:loc]
        end
      end

      lecturer = datas[6].text
      notes = rows[index+1].css('td').first.text
      required = datas[4].text.include?("必")

      if detail
        r = RestClient.get detail_url
        doc = Nokogiri::HTML(r.to_s)
        references = []
        textbook = nil
        begin
          refs = doc.css('.block1:contains("Reading") table').last.css('tr:not(:first-child)')
          refs.each do |ref|
            columns = ref.css('td')
            lib_url = nil || columns[5].css('a')[0]["href"] if columns[5].css('a').count != 0
            references << {
              type: columns[1].text,
              language: columns[2].text,
              media_type: columns[3].text,
              name: columns[4].text,
              lib_url: lib_url
            }
          end
          textbook = references.select { |r| r[:type] == "Textbook" }
        rescue Exception => e
        end
      end

      @courses << {
        :name => course_name,
        :code => course_code,
        :lecturer => lecturer,
        :required => required,
        :group => group,
        :department => department,
        :department_code => department_code,
        :day_1 => course_days[0],
        :day_2 => course_days[1],
        :day_3 => course_days[2],
        :day_4 => course_days[3],
        :day_5 => course_days[4],
        :day_6 => course_days[5],
        :day_7 => course_days[6],
        :day_8 => course_days[7],
        :day_9 => course_days[8],
        :period_1 => course_periods[0],
        :period_2 => course_periods[1],
        :period_3 => course_periods[2],
        :period_4 => course_periods[3],
        :period_5 => course_periods[4],
        :period_6 => course_periods[5],
        :period_7 => course_periods[6],
        :period_8 => course_periods[7],
        :period_9 => course_periods[8],
        :location_1 => course_locations[0],
        :location_2 => course_locations[1],
        :location_3 => course_locations[2],
        :location_4 => course_locations[3],
        :location_5 => course_locations[4],
        :location_6 => course_locations[5],
        :location_7 => course_locations[6],
        :location_8 => course_locations[7],
        :location_9 => course_locations[8],
        :url => detail_url,
        :eng_url => eng_url,
      }
    end

    File.write('courses.json', JSON.pretty_generate(@courses))
    @courses
  end

  private
    def current_year
      (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
    end

    def current_term
      (Time.now.month.between?(2, 7) ? 2 : 1)
    end
end

cc = YzuCourseCrawler.new(year: 2014, term: 1)
cc.courses
