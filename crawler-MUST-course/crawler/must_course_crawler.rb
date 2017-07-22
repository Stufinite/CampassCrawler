require 'crawler_rocks'
require 'pry'
require 'iconv'
require 'json'

class UchCourseCrawler

	GRADE = [
		'1',
		'2',
		'3',
		'4',
		'5',
	]
	def initialize year: nil, term: nil, update_progress: nil, after_each: nil

		@year = year
    	@term = term
    	@update_progress_proc = update_progress
        @after_each_proc = after_each
        @ic = Iconv.new('utf-8//IGNORE', 'big5')
	end

	def courses
		@courses = []

  		r = `curl -s "https://sss.must.edu.tw/cosinfo/qry_smtrcos1.asp" -H "Cookie: sto-id=FLAAAAAK; ASPSESSIONIDQCQAQTSD=KPCCCIGDIMMMAJMDJCNDODKF; TS97a291=16fbe417d85ef6eb729ff72cbd2b6b8d16b4b4d5bafa0c8055e7e4590dd7d258333efcc82f9d6d12d04aa885; TS97a291_31=5e301ac8a85472a58ac405fb1d7a9ee216b4b4d5bafa0c8000000000000000000095c1291f" -H "Origin: https://sss.must.edu.tw" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-TW,zh;q=0.8,en-US;q=0.6,en;q=0.4" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: https://sss.must.edu.tw/cosinfo/qry_smtrcos1.asp" -H "Connection: keep-alive" --data "YearList=#{@year-1911}&SmtrList=#{@term}&DeptteamList=BOE0&GradeList=1&Class123List=0" --compressed`
  		doc = Nokogiri::HTML(@ic.iconv(r))
  		dep_code = doc.css('select[name="DeptteamList"]').css('option').map{|u| u['value']}
  		dep_code[1..-1].each do |department|
  			GRADE.each do |grade|
  				puts  department + " : " + (dep_code.size-1).to_s + " / " + dep_code.index(department).to_s  + " - " + GRADE.size.to_s + " / " + (GRADE.index(grade)+1).to_s
		  		r = `curl -s "https://sss.must.edu.tw/cosinfo/qry_smtrcos1.asp" -H "Cookie: sto-id=FLAAAAAK; ASPSESSIONIDQCQAQTSD=KPCCCIGDIMMMAJMDJCNDODKF; TS97a291=16fbe417d85ef6eb729ff72cbd2b6b8d16b4b4d5bafa0c8055e7e4590dd7d258333efcc82f9d6d12d04aa885; TS97a291_31=5e301ac8a85472a58ac405fb1d7a9ee216b4b4d5bafa0c8000000000000000000095c1291f" -H "Origin: https://sss.must.edu.tw" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-TW,zh;q=0.8,en-US;q=0.6,en;q=0.4" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: https://sss.must.edu.tw/cosinfo/qry_smtrcos1.asp" -H "Connection: keep-alive" --data "YearList=#{@year-1911}&SmtrList=#{@term}&DeptteamList=#{department}&GradeList=#{grade}&Class123List=0" --compressed`
		  		doc = Nokogiri::HTML(@ic.iconv(r))

		  		index = doc.css('table tr')
		  		index[2..-1].each do |row|
		  			datas = row.css('td')

		  			course_days = []
		    		course_periods = []
		    		course_locations = []

		    		_time = datas[11].text.split /(\d-\d\d?),?(\d-\d\d?),?(\d-\d\d?)?,?(\d-\d\d?)?/
		    		if(_time.size > 0)
			    		_time[1..-1].each do |day_periods| 
			    			course_days << day_periods[0]
			    			course_periods << day_periods[2]
			    			course_locations  <<  datas[10].text.strip
			    		end
			    	end

		  			course = {
						  name: "#{datas[1].text.strip}",
						  year: @year,
						  term: @term,
						  code: "#{@year}-#{@term}-#{datas[0].text.strip}",
						  class_no: "#{datas[3].text.strip}",
						  credits: "#{datas[4].text}",
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
		  	end
	  	end
  		@courses
	end

end

cwl = UchCourseCrawler.new(year: 2015, term: 1)
File.write('courses.json', JSON.pretty_generate(cwl.courses))