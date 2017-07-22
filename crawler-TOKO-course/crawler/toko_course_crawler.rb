require 'crawler_rocks'
require 'pry'
require 'iconv'
require 'json'

class TokoCourseCrawler

	DEP = [
		100014,
		100029,
		100009,
		100028,
		100030,
		100033,
		100010,
		100034,
		100011,
		100013,
		100019,
		100031,
		100035,
		100036,
		100015,
		100016,
		100017,
		100018,
		100032,
	]

	EDUSYS = [
		1002,
		1006,
		1004,
		1008,
		1010,
		1003,
		1001,
		1009,
		1011,
		1007,
	]



	def initialize year: nil, term: nil, update_progress: nil, after_each: nil

		@year = year
    	@term = term
		@post_url = "http://coursemap.toko.edu.tw/bin/index.php?Plugin=coursemap&Action=csmapschcosrec"
		@update_progress_proc = update_progress
        @after_each_proc = after_each

	end

	def courses year: nil, term: nil, update_progress: nil, after_each: nil
		@courses = []
		
		EDUSYS.each do |edu|
			DEP.each do |dep|
				puts "degree: " + EDUSYS.size.to_s + "/" +(EDUSYS.index(edu)+1).to_s + " , dep:"+DEP.size.to_s + "/" + (DEP.index(dep)+1).to_s
				r = RestClient.post( @post_url , {
					cosrec_year: @year - 1911,
					cosrec_unit: dep,
					cosrec_edusys: edu,
					cosrec_grade: @term,
					sch_cond: 0,
					}) 

				doc = Nokogiri::HTML(r)
				index = doc.css('table[class="CTableList"]').css('tr')
				if index.size > 0
					index[1..-1].each do |row|
					datas = row.css('td')
					
					course_days = [] #TOKO K no days , periods and locations
			    	course_periods = []
			    	course_locations = []

			    	course = {
							name: datas[2].text.strip,
						  	year: @year,
						  	term: @term,
						  	code: "#{@year}-#{@term}-"+ datas[1].text.strip,
						  	degree: datas[0].text.strip,
						    credits: datas[4].text[0],
						    lecturer: datas[5].text.strip,
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
		end
		@courses
	end

end

cwl = TokoCourseCrawler.new(year: 2015, term: 1)
File.write('courses.json', JSON.pretty_generate(cwl.courses))