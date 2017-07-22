require 'capybara'
require 'pry'
require 'nokogiri'
require 'rest-client'

class Crawler
  include Capybara::DSL

  def initialize
    Capybara.current_driver = :selenium
  end


  def crawl
    r = RestClient.get "https://web085003.adm.ncyu.edu.tw/pub_depta1.aspx"
    doc = Nokogiri::HTML(r.to_s.encode('utf-8', :undef => :replace, :invalid => :replace, :replace => ''))
    option_values = doc.css('select[name="WebDep67"] option').map {|d| d[:value]}
	
  	option_values.each do |value|
      visit "https://web085003.adm.ncyu.edu.tw/pub_depta2.aspx?WebPid1=&Language=zh-TW&WebYear1=103&WebTerm1=2&WebDep67=#{value}"
  		File.open("1031/#{value}.html", 'w') {|f| f.write(html)}
  	end    	

  end


end

crawler = Crawler.new
crawler.crawl

# binding.pry
