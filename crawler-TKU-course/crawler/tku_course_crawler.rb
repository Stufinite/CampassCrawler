require 'crawler_rocks'
require 'open-uri'
require 'iconv'
require 'json'
require 'pry'
require 'capybara'
require 'capybara/poltergeist'

require 'thread'
require 'thwait'

class TkuCourseCrawler
  include CrawlerRocks::DSL
  include Capybara::DSL

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

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = "http://esquery.tku.edu.tw/acad/query.asp"
    @result_url = "http://esquery.tku.edu.tw/acad/query_result.asp"

    @download_url = "http://esquery.tku.edu.tw/acad/upload/#{@year-1911}#{@term}CLASS.EXE"
    @ic = Iconv.new("utf-8//translit//IGNORE","big5")

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app,  js_errors: false)
    end

    Capybara.javascript_driver = :poltergeist
    Capybara.current_driver = :poltergeist
  end

  def courses
    @courses = []

    visit @query_url

    # prepare department post datas
    @dep_post_datas = []

    begin
      deps_option_count = all('select[name="depts"] option').count
      (0..deps_option_count-1).each do |deps_option_index|
        deps_option = all('select[name="depts"] option')[deps_option_index]
        deps_option.select_option
        deps_option = nil

        sleep 1.5
        (0..all('select[name="dept"] option').count-1).each do |dep_option_index|
          dep_o = all('select[name="dept"] option')[dep_option_index]
          deps_option ||= all('select[name="depts"] option')[deps_option_index]
          puts dep_o.text
          begin
            @dep_post_datas << {
              deps: deps_option[:value],
              deps_name: deps_option.text,
              dep: dep_o[:value],
              dep_name: dep_o.text
            }
          rescue Exception => e; end;
        end
      end
    rescue Exception => e; binding.pry; end;

    @others_post_datas = []
    # prepare courses by category post datas
    other_option_count = all('select[name="other"] option').count
    (0..other_option_count-1).each do |other_option_index|
      other_option = all('select[name="other"] option')[other_option_index]
      other_option.select_option
      other_option = nil

      sleep 1
      (0..all('select[name="others"] option').count-1).each do |others_option_index|
        others_option = all('select[name="others"] option')[others_option_index]
        other_option ||= all('select[name="other"] option')[other_option_index]
        puts others_option.text

        begin
          @others_post_datas << {
            other: other_option[:value],
            other_name: other_option.text,
            others: others_option[:value],
            others_name: others_option.text
          }
        rescue Exception => e; end;
      end
    end

    r = RestClient.get @query_url
    @cookies = r.cookies

    @threads = []
    @dep_post_datas.each_with_index do |post_data, post_data_index|
      sleep(0.5) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < ( (ENV['MAX_THREADS'] && ENV['MAX_THREADS'].to_i) || 30)
      )
      @threads << Thread.new do
        print "#{post_data_index} / #{@dep_post_datas.count}, #{post_data[:deps_name]}-#{post_data[:dep_name]}\n"
        r = RestClient.post @result_url, {
          "func" => "go",
          "R1" => "1",
          "depts" => post_data[:deps],
          "sgn1" => '-',
          "dept" => post_data[:dep],
          "level" => 999
        }, cookies: @cookies
        doc = Nokogiri::HTML(@ic.iconv(r.to_s))

        parse_courses(doc, post_data)
      end # end Thread
    end # end each post_data

    @others_post_datas.each_with_index do |post_data, post_data_index|
      sleep(0.5) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < ( (ENV['MAX_THREADS'] && ENV['MAX_THREADS'].to_i) || 30)
      )
      @threads << Thread.new do
        print "#{post_data_index} / #{@others_post_datas.count}, #{post_data[:other_name]}-#{post_data[:others_name]}\n"
        r = RestClient.post @result_url, {
          "func" => "go",
          "R1" => "5",
          "other" => post_data[:other],
          "sgn1" => '-',
          "others" => post_data[:others],
          "level" => 999
        }, cookies: @cookies
        doc = Nokogiri::HTML(@ic.iconv(r.to_s))

        parse_courses(doc, post_data)
      end # end Thread
    end # end each post_data

    ThreadsWait.all_waits(*@threads)

    @courses.uniq!
    @threads = []
    @courses.each do |course|
      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < ( (ENV['MAX_THREADS'] && ENV['MAX_THREADS'].to_i) || 20)
      )
      @after_each_proc.call(course: course) if @after_each_proc
    end
    ThreadsWait.all_waits(*@threads)
    @courses
  end

  def parse_courses doc, post_data
    dep_regex = /系別\(Department\)\：(?<dep_c>.+)\.(?<dep_n>.+)\u3000/
    course_rows = doc.css('table[bordercolorlight="#0080FF"] tr').select do |course_row|
      !course_row.text.include?('系別(Department)') &&
      !course_row.text.include?('選擇年級') &&
      !course_row.text.include?('教學計畫表') &&
      !course_row.text.strip.empty?
    end

    department = post_data[:dep_name]
    department_code = post_data[:dep]

    @year = doc.css('big').text.scan(/\d+/)[0].to_i + 1911
    @term = doc.css('big').text.scan(/\d+/)[1].to_i

    course_rows.each_with_index do |course_row, course_row_index|
      datas = course_row.css('td')
      next_course_row = course_rows[course_row_index+1]

      begin
        serial_no = datas[2] && datas[2].text.to_i.to_s.rjust(4, '0')
        if datas[2].text.strip.gsub(/\u3000/, '') == "(正課)"
          serial_no = (next_course_row.css('td')[2].text.to_i - 1).to_s.rjust(4, '0')
        end
      rescue
        binding.pry
        puts 'hello'
      end

      # code = datas[3] && datas[3].text.strip.gsub(/\u3000/, '')
      general_code = datas[3] && datas[3].text.strip.gsub(/\u3000/, '')
      class_code = datas[6] && datas[6].text.strip.gsub(/\u3000/, '')
      group_code = datas[7] && datas[7].text.strip.gsub(/\u3000/, '')
      class_group_code = datas[10] && datas[10].text.strip.gsub(/\u3000/, '')
      # code = "#{@year}-#{@term}-#{code}-#{serial_no}-#{class_code}-#{group_code}-#{department_code}"
      # code = "#{@year}-#{@term}-#{code}-#{serial_no}-#{department_code}"
      # code = "#{@year}-#{@term}-#{code}-#{class_code}-#{group_code}-#{department_code}"
      code = "#{@year}-#{@term}-#{general_code}-#{class_code}-#{group_code}-#{department_code}"


      lecturer = ""
      if datas[13].nil?
        binding.pry
      end
      datas[13] && datas[13].text.match(/(?<lec>.+)?\ \([\d|\*]+\)/) do |m|
        lecturer = m[:lec]
      end


      course_days = []
      course_periods = []
      course_locations = []
      datas[14..15].each do |time_loc_col|
        t_raws = time_loc_col.text.split('/').map{|tt| tt.strip}
        t_raws[1] && t_raws[1].split(',').each do |p|
          course_days << DAYS[t_raws[0]]
          course_periods << p.to_i
          course_locations << t_raws[2].gsub(/\u3000/, ' ').gsub(/\s+/, ' ')
        end
      end

      name = datas[11] && datas[11].css('font')[0] && datas[11].css('font')[0].text.gsub(/\u3000/, ' ').strip

      @courses << {
        year: @year,
        term: @term,
        code: code,
        serial_no: serial_no,
        class_code: class_code,
        group_code: group_code,
        class_group_code: class_group_code,
        general_code: general_code,
        # preserve notes for notes
        name: "#{name} (#{class_code})",
        lecturer: lecturer,
        department: department,
        department_code: department_code,
        required: datas[8] && datas[8].text.include?('必'),
        credits: datas[9] && datas[9].text.to_i,
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

    end # end each row
  end # end parse_courses method


  def parse_from_local
    @courses = []

    Dir.glob('tmp/1041/*.htm').each do |filename|
      doc = Nokogiri::HTML(@ic.iconv(File.read(filename)))

      @year = doc.css('big').text.scan(/\d+/)[0].to_i + 1911
      @term = doc.css('big').text.scan(/\d+/)[1].to_i

      course_rows = doc.xpath('//table[@bordercolorlight="#0080FF"]/tr')
      title_rows = course_rows.select{|row| row.text.include?('系別(Department)')}

      (0..title_rows.count-2).each do |title_row_index|
        _start = course_rows.index(title_rows[title_row_index]) + 3
        _end = course_rows.index(title_rows[title_row_index+1]) - 1

        title_row = title_rows[title_row_index]

        dep_regex = /系別\(Department\)\：(?<dep_c>.+)\.(?<dep_n>.+)\u3000/
        department = nil; department_code = nil;
        title_row.text.match(dep_regex) do |m|
          department_code = m[:dep_c]
          department = m[:dep_n]
        end

        (_start.._end).each do |course_row_index|
          course_row = course_rows[course_row_index]
          datas = course_row.css('td')

          next_course_row = course_rows[course_row_index+1]

          # begin
          #   serial_no = datas[1] && datas[1].text.to_i.to_s.rjust(4, '0')
          #   if datas[1].text == "(正課)　"
          #     serial_no = (next_course_row.css('td')[1].text.to_i - 1).to_s.rjust(4, '0')
          #   end
          # rescue
          #   binding.pry
          #   # puts 'hello'
          # end

          general_code = datas[2] && datas[2].text.strip.gsub(/\u3000/, '')
          class_code = datas[5] && datas[5].text.strip.gsub(/\u3000/, '')
          group_code = datas[6] && datas[6].text.strip.gsub(/\u3000/, '')
          # code = "#{@year}-#{@term}-#{code}-#{serial_no}-#{department_code}"
          code = "#{@year}-#{@term}-#{general_code}-#{class_code}-#{group_code}-#{department_code}"

          lecturer = ""
          if datas[12].nil?
            binding.pry
          end
          datas[12] && datas[12].text.match(/(?<lec>.+)?\ \([\d|\*]+\)/) do |m|
            lecturer = m[:lec]
          end

          course_days = []
          course_periods = []
          course_locations = []
          datas[13..14].each do |time_loc_col|
            t_raws = time_loc_col.text.split('/').map{|tt| tt.strip}
            t_raws[1] && t_raws[1].split(',').each do |p|
              course_days << DAYS[t_raws[0]]
              course_periods << p.to_i
              course_locations << t_raws[2].gsub(/\u3000/, ' ').gsub(/\s+/, ' ')
            end
          end

          name = datas[10] &&  datas[10].css('font')[0] && datas[10].css('font')[0].text.gsub(/\u3000/, ' ').strip

          @courses << {
            year: @year,
            term: @term,
            code: code,
            general_code: general_code,
            # preserve notes for notes
            name: "#{name} (#{class_code})",
            lecturer: lecturer,
            department: department,
            department_code: department_code,
            required: datas[7] && datas[7].text.include?('必'),
            credits: datas[8] && datas[8].text.to_i,
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
    end

    @courses.uniq!
    @threads = []
    @courses.each do |course|
      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < ( (ENV['MAX_THREADS'] && ENV['MAX_THREADS'].to_i) || 30)
      )
      @after_each_proc.call(course: course) if @after_each_proc
    end
    ThreadsWait.all_waits(*@threads)

    @courses
  end

  def current_year
    (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
  end

  def current_term
    (Time.now.month.between?(2, 7) ? 2 : 1)
  end
end

# cc = TkuCourseCrawler.new
# File.write('1041_tku_courses_remote.json', JSON.pretty_generate(cc.courses))

# cc = TkuCourseCrawler.new
# File.write('1041_tku_courses.json', JSON.pretty_generate(cc.parse_from_local))
