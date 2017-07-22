require 'crawler_rocks'
require 'pry'
require 'iconv'
require 'json'


class CjcuCourseCrawler

	DEP = [
	'ABA',
	'AIB',
	'AAI',
	'AAM',
	'ALD',
	'AFI',
	'ATM',
	'ASR',
	'ALM',
	'AEF',
	'AME',
	'AFB',
	'AHA',
	'ANS',
	'ANU',
	'AOH',
	'ABT',
	'AHP',
	'AHD',
	'AFS',
	'APE',
	]

	Grade = [
	'1'	,
	'2' ,
	'3' ,
	'4' ,
	]

	Class = [
	'1'	,
	'2' ,
	'3' ,
	'4' ,
	]


	DAYS = {
		'一' => 1,
		'二' => 2,
		'三' => 3,
		'四' => 4,
		'五' => 5,
		'六' => 6,
		'日' => 7
	}


	def initialize year: nil, term: nil, update_progress: nil, after_each: nil

		@year = year
    	@term = term # 1 => 1 , 2 => 2 , summer1 => 5 , summer2 => 6
    	
    	@ic = Iconv.new('utf-8//translit//IGNORE', 'utf-8') 
    	@update_progress_proc = update_progress
   		@after_each_proc = after_each

	end

	def courses 
		@courses = []

		year = @year
    	term = @term #initialize -> year and term

    	Grade.each do |grade| #grade
    		DEP.each do |department| # dep 
    			puts "grade: " + Grade.size.to_s + "/" +(Grade.index(grade)+1).to_s + " , dep:"+DEP.size.to_s + "/" + (DEP.index(department)+1).to_s
    			Class.each do |class_no| # class_name

					@url_Get = "https://eportal.cjcu.edu.tw/api/Course/Get/?syear=#{year-1911}&semester=#{term}&dep="+department+"&grade="+grade+"&classno="+class_no+" "
					r = RestClient.get @url_Get , accept: 'application/json'
					#doc = Nokogiri::HTML(r)

        			data = JSON.parse(r)
        			data.each do |array| 
    

    				# regex = /\[(.)\][A-Z]{3}\s\((.+)\)(.+)/
    				course_regex = /星期(?<d>.)\((?<s>\d+)節~(?<e>\d+)節\)(?<loc>([^星期]+)?)/
    				course_arrange_time_info = Nokogiri::HTML(array["course_arrange_time_info"]).text

       				course_days = []
    				course_periods = []
    				course_locations = []

    				course_arrange_time_info.scan(course_regex).each do |match_arr|
    					(match_arr[1].to_i..match_arr[2].to_i).each do |period|
    						course_days << DAYS[match_arr[0]]
    						course_periods << period
    						course_locations << match_arr[3]
    					end
    				end


	    			course = {
	  					name: array["course_name"],
	 					code: array["open_no"],
	  					credits: array["credit"],
	  					grade: array["grade"],
	  					class_name: array["class_name"],
	  					lecturer: array["master_teacher_name"],
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
	puts "ForeignLanguages : Running..."
	@url_GetInForeign = "https://eportal.cjcu.edu.tw/api/Course/GetByTaughtInForeignLanguages/?syear=#{year-1911}&semester=#{term}"
	r_Foregin = RestClient.get @url_GetInForeign , accept: 'application/json'
		
	data_Foregin = JSON.parse(r_Foregin)
	data_Foregin.each do |array| 

		course_regex = /星期(?<d>.)\((?<s>\d+)節~(?<e>\d+)節\)(?<loc>([^星期]+)?)/
		course_arrange_time_info = Nokogiri::HTML(array["course_arrange_time_info"]).text

			course_days = []
		course_periods = []
		course_locations = []

		course_arrange_time_info.scan(course_regex).each do |match_arr|
			(match_arr[1].to_i..match_arr[2].to_i).each do |period|
				course_days << DAYS[match_arr[0]]
				course_periods << period
				course_locations << match_arr[3]
			end
		end

	    course = {
	  		name: array["course_name"],
	 		code: array["open_no"],
	  		credits: array["credit"],
	  		grade: array["grade"],
	  		class_name: array["class_name"],
	  		lecturer: array["master_teacher_name"],
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
    puts "End"
	@courses
	end
end

cwl = CjcuCourseCrawler.new(year: 2015, term: 1)
File.write('courses.json', JSON.pretty_generate(cwl.courses))