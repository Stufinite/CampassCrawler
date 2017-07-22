require 'crawler_rocks'
require 'pry'
require 'iconv'
require 'json'

class TsuCourseCrawler

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    #@url = "http://eportfolio.tsu.edu.tw/bin/index.php?Plugin=coursemap&Action=schoolcourse"
    #@post_url = "http://eportfolio.tsu.edu.tw/bin/index.php?Plugin=coursemap&Action=course&TagName=id_YSK_search_result"
  	@year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each
  end

  def courses
    @courses = []

    #r = RestClient.get @url
    #cookies = r.cookies

 	year = @year
    term = @term

    # from Curl 
    r = `curl -s 'http://eportfolio.tsu.edu.tw/bin/index.php?Plugin=coursemap&Action=course&TagName=id_YSK_search_result' -H 'id_YSK_search_result=%2Fbin%2Findex.php%3FPlugin%3Dcoursemap%26Action%3Dcourse%26TagName%3Did_YSK_search_result; PageLang=zh-tw; _counter=137857' --data 'rs=sajaxSubmit&rsargs[]=%3CInput%3E%3CF%3E%3CK%3Eyear%3C/K%3E%3CV%3E#{year-1911}%3C/V%3E%3C/F%3E%3CF%3E%3CK%3Esemester%3C/K%3E%3CV%3E#{term}%3C/V%3E%3C/F%3E%3CF%3E%3CK%3Edegree%3C/K%3E%3CV%3E%3C/V%3E%3C/F%3E%3CF%3E%3CK%3Ecollege%3C/K%3E%3CV%3E%3C/V%3E%3C/F%3E%3CF%3E%3CK%3Edept%3C/K%3E%3CV%3E%3C/V%3E%3C/F%3E%3CF%3E%3CK%3Egrade%3C/K%3E%3CV%3E%3C/V%3E%3C/F%3E%3CF%3E%3CK%3Ebyteacher%3C/K%3E%3CV%3E0%3C/V%3E%3C/F%3E%3CF%3E%3CK%3Eundefined%3C/K%3E%3CV%3Eundefined%3C/V%3E%3C/F%3E%3CF%3E%3CK%3Ekeyword%3C/K%3E%3CV%3E%25E8%25AB%258B%25E8%25BC%25B8%25E5%2585%25A5%25E9%2597%259C%25E9%258D%25B5%25E5%25AD%2597%3C/V%3E%3C/F%3E%3CF%3E%3CK%3E%3C/K%3E%3CV%3E%25E6%259F%25A5%25E8%25A9%25A2%3C/V%3E%3C/F%3E%3CF%3E%3CK%3EdgrName%3C/K%3E%3CV%3E%3C/V%3E%3C/F%3E%3CF%3E%3CK%3EcollegeName%3C/K%3E%3CV%3E%3C/V%3E%3C/F%3E%3CF%3E%3CK%3EdeptName%3C/K%3E%3CV%3E%3C/V%3E%3C/F%3E%3CF%3E%3CK%3EOp%3C/K%3E%3CV%3EsBySch%3C/V%3E%3C/F%3E%3C/Input%3E' --compressed`
   
    doc = Nokogiri::HTML(r)

    index_class = doc.css('table[class="cstable"]').css('tr')[1..-1]
     index_class.each do |row|
    	datas = row.css('td')
    	puts  "課程進度: "+index_class.size.to_s + "/" +  (index_class.index(row)+1).to_s

    	course_days = []   # no days , periods and locations
    	course_periods = []
    	course_locations = []

    	course = {
		  name: "#{datas[3].text.strip}",
		  year: @year,
		  term: @term,
		  code: nil,
		  degree: "#{datas[0].text.strip}",
		  class_: "#{datas[2].text.strip}",
		  credits: "#{datas[7].text.strip}",
		  lecturer: "#{datas[9].text.strip}",
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

    end

    @courses
  end
end

cwl = TsuCourseCrawler.new(year: 2015, term: 1)
File.write('courses.json', JSON.pretty_generate(cwl.courses))