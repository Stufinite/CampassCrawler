require 'crawler_rocks'
require 'pry'
require 'json'

require 'thread'
require 'thwait'

class NcuCourseCrawler

  DAYS = {
    "Mon" => 1,
    "Tue" => 2,
    "Wed" => 3,
    "Thu" => 4,
    "Fri" => 5,
    "Sat" => 6,
    "Sun" => 7,
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7,
  }

  PERIODS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "Z" => 5,
    "5" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "9" => 10,
    "A" => 11,
    "B" => 12,
    "C" => 13,
    "D" => 14,
    "E" => 15,
    "F" => 16,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @query_url = "https://course.ncu.edu.tw/Course/main/query/byKeywords"

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

  end

  def courses
    @courses = {}
    @get_datas = []

    r = RestClient.get "https://course.ncu.edu.tw/Course/main/query/byClass", accept_language: 'zh-TW'
    doc = Nokogiri::HTML(r.to_s)

    doc.xpath('//td[@valign="top"]/table/tr[2]/td/ul/li').each do |list|
      dep_n = list.xpath('a').text.match(/(.+?)\s*\((\d+)\)/)[1]
      # deptdeptI0I8I0 discard dept from begining
      dep_c = list.xpath('ul/@id').to_s.match(/(?<=deptdept).+/)[0].delete('I')
      list.xpath('ul/li/a').each do |a|
        m = a.text.match(/(.+?)\s*\((\d+)\)/)
        grp_c = a[:href].match(/(?<=ZcofgI).+/)[0]
        @get_datas << {
          dep_n: dep_n,
          dep_c: dep_c,
          grp_n: m[1],
          grp_c: grp_c,
          amount: m[2].to_i,
          url: URI.join(@query_url, a[:href]).to_s
        }
      end
    end

    @threads = []
    @get_datas.each do |get_data|
      department = "#{get_data[:dep_n]}#{get_data[:grp_n]}"
      department_code = "#{get_data[:dep_c]}-#{get_data[:grp_c]}"

      page_count = get_data[:amount] / 50 + 1
      print "#{department}\n"

      (1..page_count).each do |i|
        sleep(1) until (
          @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
          @threads.count < (ENV['MAX_THREADS'] || 20)
        )
        @threads << Thread.new do
          print "#{i}|"
          r = RestClient.get( get_data[:url] + "&d-49489-p=#{i}", accept_language: 'zh-TW' )
          doc = Nokogiri::HTML(r)
          doc.css('table#item tbody tr').each do |row|
            parse_row(row, department_code, department)
          end
        end # end thread
      end
    end
    ThreadsWait.all_waits(*@threads)

    @courses.values
  end

  # deprecated
  def parse_by_capybara
    visit "#{@query_url}?#{URI.encode({
      "query" => "查詢",
      "fall_spring" => @term,
      "year" => @year-1911,
      "d-49489-p" => 1,
      "week" => 1
    }.map{|k, v| "#{k}=#{v}"}.join('&'))}"

    doc = Nokogiri::HTML html;
    dep_h = Hash[doc.css('select[name="selectDept"] option').map{|d| [d[:value], d.text.gsub(/　/, '')]}.select {|arr| arr[0].match(/^#{@year-1911}#{@term}/)}]

    dep_h.each do |dep_code, dep|
      puts dep
      page_count = 1
      # visit each department
      r = RestClient.get("#{@query_url}?#{URI.encode({
        "query" => "查詢",
        "fall_spring" => @term,
        "year" => @year-1911,
        "d-49489-p" => page_count,
        "selectDept" => dep_code,
        "week" => 1
      }.map {|k, v| "#{k}=#{v}"}.join('&'))}", accept_language: 'zh-TW')

      while true
        print "#{page_count}, "
        page_count += 1

        doc = Nokogiri::HTML(r.to_s)
        doc.css('table#item tbody tr').each do |row|
          parse_row(row, dep_code.match(/^#{@year-1911}#{@term}(?<dep_c>.*)/)[:dep_c], dep)
        end

        next_page = doc.css('.pagelinks a:contains("»")')
        if next_page.empty?
          break
        else
           r = RestClient.get "https://course.ncu.edu.tw#{next_page[0][:href]}", accept_language: 'zh-TW'
        end
      end
    end
  end

  def parse_row row, dep_code, dep
    datas = row.css("td")

    _url = datas[9] && datas[9].css('a')[0] && datas[9].css('a')[0][:onclick][25..-4]
    url = "https://course.ncu.edu.tw#{_url}"

    year_term = url.match(/(?<=semester=).+/).to_s
    year = year_term[0..-2].to_i + 1911
    term = year_term[-1].to_i

    name = datas[1] && datas[1].text && datas[1].text.strip
    names = name.split(/\n+/)
    names.each {|d,i| d.strip!}
    names.each {|d| names.delete(d) if d.empty? }

    times = datas[4] && datas[4].text && datas[4].search('br').each {|d| d.replace("\n")} && datas[4].text.strip.split("\n")

    course_days = []
    course_periods = []
    course_locations = []
    if times
      times.each do |time|
        time.match(/(?<d>(#{DAYS.keys.join('|')}))(?<p>[#{PERIODS.keys.join}]+)\/(?<loc>.+)/) do |m|
          m[:p].split("").each do |period|
            course_days << DAYS[m[:d]]
            course_periods << PERIODS[period]
            course_locations << m[:loc]
          end
        end
      end
    end

    general_code = datas[0] && datas[0].text
    code = "#{year}-#{term}-#{general_code}-#{dep_code.to_s}"

    course = {
      year: year,
      term: term,
      code: code,
      general_code: general_code,
      department_code: dep_code.to_s,
      department: dep,
      name: names[0],
      english_name: names[1],
      lecturer: datas[2] && datas[2].text && datas[2].text.strip,
      credits: datas[3] && datas[3].text && datas[3].text.to_i,
      required: datas[5] && datas[5].text && datas[5].text.include?('必'),
      # semester: datas[6] && datas[6].text && datas[6].text.strip,
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
    @after_each_proc.call(course: course) if @after_each_proc
    @courses[code] = course
  end

  def current_year
    (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
  end

  def current_term
    (Time.now.month.between?(2, 7) ? 2 : 1)
  end

  def page_links
    @doc.css('.pagelinks a').map{|a| a.text} | @doc.css('.pagelinks strong').map{|a| a.text}
  end
end


# cc = NcuCourseCrawler.new(year: 2015, term: 1)
# File.write('1041_ncu_courses.json', JSON.pretty_generate(cc.courses))
