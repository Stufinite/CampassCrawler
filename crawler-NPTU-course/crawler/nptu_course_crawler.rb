require 'crawler_rocks'
require 'pry'
require 'iconv'

class NptuCourseCrawler
  include CrawlerRocks::DSL

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil


    @search_url = "http://webs8.nptu.edu.tw/selectn/search.asp"
    @result_url = "http://webs8.nptu.edu.tw/selectn/clist.asp"

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

  end

  def courses
    @courses = []
    ic = Iconv.new("utf-8//translit//IGNORE","big5")

    visit @search_url
    deps = @doc.css('select[name="dept"] option:not(:first-child)').map{|opt| opt.text.strip}
    sects = @doc.css('select[name="sect"] option:not(:first-child)').map{|opt| opt.text.strip}
    grads = @doc.css('select[name="grade"] option:not(:first-child)').map{|opt| opt.text.strip}

    @doc.css('h2').text.match(/(?<year>\d+)學年度第(?<term>\d)學期課表查詢/) do |m|
      @year = m[:year].to_i + 1911
      @term = m[:term].to_i
    end

    deps.each do |dep|
    sects.each do |sect|
    grads.each do |grade|
      puts "#{dep} - #{sect} - #{grade}"
      begin
        r = RestClient.post @result_url, {
          dept: dep,
          sect: sect,
          grade: grade
        }
        doc = Nokogiri::HTML(ic.iconv(r))
        parse(doc, dep, sect, grade)
      rescue RestClient::RequestTimeout => e
        puts "error"
        next
      end
    end; end; end;

    File.write('courses.json', JSON.pretty_generate(@courses))
  end

  def parse(doc, dep, sect, grade)
    doc.css('table')[0].css('tr:not(:first-child)').each do |row|
      datas = row.css('td')

      required_raw = datas[3] && datas[3].text

      course_days = []
      course_periods = []
      course_locations = []
      location = datas[18] && datas[18].text.strip
      datas[10..16].each_with_index do |data, d|
        m = data.text.match(/(?<p>\d+)/)
        if !!m && m[:p]
          m[:p].split("").each do |p|
            course_days << d+1
            course_periods << p
            course_locations << location
          end
        end
      end

      @courses << {
        year: @year,
        term: @term,
        department: sect,
        grade: grade,
        code: datas[0] && datas[0].text,
        name: datas[1] && datas[1].text,
        url: datas[1] && datas[1].css('a') && datas[1].css('a')[0] && datas[1].css('a')[0][:href],
        domain: datas[2] && datas[2].text.strip,
        required: required_raw && required_raw[1..-1].strip.include?('必'),
        credits: datas[4] && datas[4].text.to_i,
        lecturer: datas[9] && datas[9].text.strip,
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
    end # doc each row

  end

  def current_year
    (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
  end

  def current_term
    (Time.now.month.between?(2, 7) ? 2 : 1)
  end
end

cc = NptuCourseCrawler.new(year: 2014, term: 1)
cc.courses
