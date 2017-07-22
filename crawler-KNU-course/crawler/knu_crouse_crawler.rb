require 'crawler_rocks'
require 'pry'
require 'iconv'
require 'json'

class KnuCrouseCrawler

	DEP = [
		4,
		9,
		5,
		6,
		7,
		8,
		10,
		11,
		13,
		15,
		16,
		17,
		18,
		19,
		20,
		21,
		22,
		48,
		24,
	]

	DEGREE = [
		1006,
		1010,
		1009,
		1007,
		1008,
	]

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil

		@year = year
    	@term = term
		#@url = "http://coumap.eportfolio.knu.edu.tw/files/11-1001-83.php"
		@post_url = "http://coumap.eportfolio.knu.edu.tw/bin/index.php?Plugin=coursemap&Action=csmapschcosrec"
		@update_progress_proc = update_progress
        @after_each_proc = after_each

	end 

	def courses
		@courses = []

		DEGREE.each do |deg|
			DEP.each do |dep|
				puts "degree: " + DEGREE.size.to_s + "/" +(DEGREE.index(deg)+1).to_s + " , dep:"+DEP.size.to_s + "/" + (DEP.index(dep)+1).to_s
				r = RestClient.post( @post_url , { #post network
					cosrec_year: @year-1911,
					cosrec_unit: dep,
					cosrec_edusys: deg,
					cosrec_grade: @term,
		    		sch_cond: 0,
		    		})

				doc = Nokogiri::HTML(r) # XML to HTML

				course_days = [] # KNU no days , periods and locations
		    	course_periods = []
		    	course_locations = []

				class_num = doc.css('#csmap_cos_table tr').count
				1.upto(class_num-1) do |num|
					data = doc.css('#csmap_cos_table tr')[num].css('td')
					course = {
						name: data[2].text.strip,
					  	year: @year,
					  	term: @term,
					  	code: "#{@year}-#{@term}-"+ data[1].text.strip,
					  	degree: data[0].text.strip,
					    credits: data[4].text.strip[0],
					    lecturer: data[5].text.strip,
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

cwl = KnuCrouseCrawler.new(year: 2015, term: 1)
File.write('courses.json', JSON.pretty_generate(cwl.courses))