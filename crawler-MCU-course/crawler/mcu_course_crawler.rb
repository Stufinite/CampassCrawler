require 'crawler_rocks'

require 'iconv'
require 'pry'

require 'thread'
require 'thwait'

class McuCourseCrawler
  include CrawlerRocks::DSL

  PERIODS = {
    "01" =>  1,
    "02" =>  2,
    "03" =>  3,
    "04" =>  4,
    "20" =>  5,
    "05" =>  6,
    "06" =>  7,
    "07" =>  8,
    "08" =>  9,
    "09" => 10,
    "40" => 11,
    "50" => 12,
    "60" => 13,
    "70" => 14,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @get_url = "http://www.mcu.edu.tw/student/new-query/sel-query/qslist.asp"
    @post_url = "http://www.mcu.edu.tw/student/new-query/sel-query/qslist_1.asp"
    @detail_base_url = "https://tch.mcu.edu.tw/sylwebqry/pro10_22.aspx"

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @ic = Iconv.new("utf-8//IGNORE//translit","big5")
  end

  def courses
    @preload_url = "http://www.mcu.edu.tw/student/new-query/sel-query/query_0_1.asp?gdb=#{@term}&gyy=#{@year-1911}"
    @courses = []

    # start crawl
    visit @preload_url
    visit @get_url

    error_urls = []
    # 跳過不限
    schs = @doc.css('select[name="sch"] option')[1..-1].map{|k| k['value']}

    # save departments hash
    departments = Hash[@doc.css('select[name="dept1"] option')[1..-1].map {|k| ss = k.text.strip.split(' - '); [ss[0], ss[1]]}]
    Dir.mkdir('tmp') if not Dir.exist?('tmp')
    File.write('tmp/departments.json', JSON.pretty_generate(departments))

    @total_department_count = schs.count
    @processed_department_count = 0

    schs.each_with_index do |sch, ii|
      # @threads << Thread.new do
        r = RestClient.post(@post_url, {
          sch: sch
        }, cookies: @cookies)

        doc = Nokogiri::HTML(@ic.iconv(r))
        rows = doc.css('table tr:not(:first-child)')

        # progress = ProgressBar.create(:title => "#{ii}", :total => rows.count)
        rows.each do |row|
          # progress.increment

          datas = row.css('td')
          type = datas[0].text

          serial_no ||= nil; course_name ||= nil
          datas[1].text.match /(?<serial>\d{5})\s(?<name>.+)/ do |m|
            serial_no = m[:serial]
            course_name = m[:name]
          end

          department ||= nil; group_code ||= nil;
          group_name ||= nil; department_code ||= nil;
          datas[2].text.match(/(?<gc>(?<dc>\d{2})\d{3})\s?(?<gn>.+)/) do |m|
            department = departments[m[:dc]]
            department_code = m[:dc]
            group_code = m[:gc]
            group_name = m[:gn]
          end

          detail_url = datas[4].css('a')[0]['href']
          sche_raw = datas[5].text
          raws = sche_raw.split('節')
          locs = datas[7].text.split("\n")

          course_days = []
          course_periods = []
          course_locations = []

          if raws.count == 1 && raws[0].gsub(/\s+/, '') == ":"
            # schedule = nil
          else # valid
            raws.each_with_index do |raw, i| # 星期 1 : 05  06
              rrrs = raw.split(':') # ["星期 1 ", " 05  06"]
              day = rrrs.first.match(/\d/).to_s # 1
              hours = rrrs.last.split(' ') # ["05", "06"]

              # new periods format
              hours.each do |period|
                course_days << day.to_i
                course_periods << PERIODS[period]
                course_locations << locs[i]
              end
            end
          end

          # 剩下幾個欄位就先沒弄了
          # 詳細頁面先抓書就好...沒時間啦ww
          # tcls=00101&tcour=00755&tyear=103&tsem=2&type=1
          # detail_url = "#{detail_base_url}?tcls=#{group_code}&tcour=#{serial_no}&tyear=103&teac=&tsem=2&type=1"
          # begin
          #   doc = Nokogiri::HTML((RestClient.get(detail_url, :cookies => cookie)).to_s)
          #   book = doc.css('#panShow1 tr:nth-child(7) td').text.strip
          # rescue Exception => e
          #   puts detail_url
          #   error_urls << detail_url
          #   book = nil
          # end

          datas[4] && datas[4].search('br').each{|br| br.replace("\n")}
          lecturer = datas[4] && datas[4].text.split("\n").map{|txt| txt.rpartition(':')[-1].strip}.join(',')

          @courses << {
            year: @year,
            term: @term,
            code: "#{@year}-#{@term}-#{serial_no}-#{group_code}",
            general_code: serial_no,
            name: course_name,
            lecturer: lecturer,
            department: department,
            department_code: department_code,
            group_name: group_name,
            group_code: group_code,
            url: detail_url,
            # grade: datas[6] && datas[6].text.to_i,
            required: datas[8] && datas[8].text.include?('必'),
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
            # :book => book
          }
        end # rows.each do
        puts "done #{@processed_department_count} / #{@total_department_count}"
        @processed_department_count += 1
      # end # Thread.new
    end # schs.each_with_index do
    @courses.uniq!

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
  end # def course
end # class McuCourseCrawler

# cc = McuCourseCrawler.new(year: 2014, term: 1)
# File.open('mcu_courses.json', 'w') {|f| f.write(JSON.pretty_generate(cc.courses))}
