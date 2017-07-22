require 'capybara'
require 'selenium-webdriver'
require 'capybara/poltergeist'
require 'json'
require 'pry'
require 'nokogiri'
require 'rest_client'
require 'ruby-progressbar'
require 'crawler_rocks'

class Crawler
  include Capybara::DSL
  def initialize

    Capybara.register_driver :poltergeist_with_long_timeout do |app|
      Capybara::Poltergeist::Driver.new(app, :timeout => 300)
    end

    Capybara.default_driver = :poltergeist_with_long_timeout
    Capybara.javascript_driver = :poltergeist_with_long_timeout
    Capybara.default_wait_time = 2

  end

  def crawl
    return if File.exist?('courses.html')
    visit "https://portal.yzu.edu.tw/cosSelect/Index.aspx?Lang=TW"
    choose '課程關鍵字'
    #fill_in('Txt_Cos_Name', with: " ")
    find('#Txt_Cos_Name').set(' ')
    find('#Button2').click

    File.open('courses.html', 'w') {|f| f.write(html) }
  end

  def parse_with_nokogiri
    doc = Nokogiri::HTML(File.read('courses.html'))

    @courses = []
    rows = doc.css('#Table1 tr:not(:first-child)')
    progressbar = ProgressBar.create(:total => rows.count)
    rows.each_with_index do |row, index|
      progressbar.increment
      if index % 2 == 1
        next
      end

      # beautiful css QAQ
      detail_url = "https://portal.yzu.edu.tw/cosSelect".concat row.css('td')[1].css('a')[0]["href"][1..-1]
      course_code = row.css('td')[1].text
      classs = row.css('td')[2].text
      course_name = row.css('td')[3].css('*')[0].text
      eng_url = "https://portal.yzu.edu.tw/cosSelect".concat row.css('td')[3].css('*')[1][:href][1..-1]
      course_type = row.css('td')[4].text

      loc_time = {}
      loc_time_raws = row.css('td')[5].text.split(' ')
      loc_time_raws.each do |raw|
        tim, loc = raw.split(',')
        loc_time[tim] = loc
      end

      lecturer = row.css('td')[6].text
      notes = rows[index+1].css('td').first.text
      required = row.css('td')[4].text.include?("必")

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

      @courses << {
        :url => detail_url,
        :code => course_code,
        :class => classs,
        :name => course_name,
        :eng_url => eng_url,
        :type => course_type,
        :time_location => loc_time,
        :lecturer => lecturer,
        :note => notes,
        :references => references,
        :textbook => textbook,
        :required => required
      }
    end

    return @courses

  end

end

crawler = Crawler.new
crawler.crawl
courses = crawler.parse_with_nokogiri

binding.pry
File.open('courses.json', 'w') {|f| f.write(JSON.pretty_generate(courses))}
