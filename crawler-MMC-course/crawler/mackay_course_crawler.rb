require 'crawler_rocks'
require 'pry'
require 'iconv'
require 'json'

class MackayCourseCrawler

	DEP = [
		910,
		500,
		510,
		520,
		610,
		620,
		630,
	]
	GRADE = [
		1,
		2,
		3,
		4,
		5,
		6,
		7,
	]

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil
		@year = year
    	@term = term
		@post_url = "http://portal.mmc.edu.tw/VC2/global_cos.aspx"
		@update_progress_proc = update_progress
        @after_each_proc = after_each
	end

	def courses
		@courses = []

		year = @year
		term = @term


		DEP.each do |dep|
			GRADE.each do |grade|
				puts "grade: " + GRADE.size.to_s + "/" +(GRADE.index(grade)+1).to_s + " , dep:"+DEP.size.to_s + "/" + (DEP.index(dep)+1).to_s
				r = RestClient.post( @post_url , {
					__VIEWSTATE:'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',
					__EVENTVALIDATION:'/wEWJwLkkqjlAQL3zqy8CQL3ztgYAvfO9PUIAvfO4K4HAvfOnIsOAuuauNAJAsjthucDAsrthucDAvXthucDAtymlZABAtymgbcOAtymkY8BAtymjbIOAoe8lqMEApi8lqMEAsL5ipEDAsP5ipEDAo3cx50FAo7cx50FAsiZ+gsCyZn6CwLj0dTwCAL30dDwCAL30dTwCAL30djwCAL30aTzCAL20dTwCAL20djwCAL20dzwCALDy9nEBQLCy9nEBQLBy9nEBQLAy9nEBQLHy9nEBQLGy9nEBQLFy9nEBQLcy9nEBQKM54rGBgkW/sxSufECtHrY1n5KMciErcZkLKkKO9vMkb1bG8Ug',
					Q:'RadioButton1',
					DDL_YM:(year-1911).to_s+','+term.to_s,
					DDL_Dept:dep,
					DDL_Degree:grade,
					Button1:'確定',
					}) 
			
					
				doc = Nokogiri::HTML(r)
				index = doc.css('table[id="Table1"]').css('tr')
				index[1..-1].each do |row|
					datas = row.css('td')
					if(datas[3]!=nil)
						#from another url , get the credits
						@url_get = "http://portal.mmc.edu.tw/VC2/Guest/Cos_Plan.aspx?y=#{year-1911}&s=#{term}&id="+datas[1].text[0..4].to_s+"&c="+datas[1].text[6].to_s
						r_get = RestClient.get @url_get
						doc_get = Nokogiri::HTML(r_get)
						#doc_get.css('div[id="Cos_info"]').css('table[class="table_1"]').css('tr')[1].css('td')[3].text

						course_days = [] 
						course_periods = []
						course_locations = []

						course_T=datas[5].text.split /(?<per>\d\d\d),(?<loc>.\d\d\d)/
						1.upto(course_T.size/3) do |x|
							course_days << course_T[3*x-2][0]
    						course_periods << course_T[3*x-2][1..-1]
    						course_locations << course_T[3*x-1]
						end

						course = {
								name: datas[3].text.strip,
								year: @year,
								term: @term,
								code: "#{@year}-#{@term}-"+ datas[1].text.strip,
								degree: datas[2].text.strip,
								credits: doc_get.css('div[id="Cos_info"]').css('table[class="table_1"]').css('tr')[1].css('td')[3].text,
								lecturer: datas[6].text.strip,
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

cwl =  MackayCourseCrawler.new(year: 2015, term: 1)
File.write('courses.json', JSON.pretty_generate(cwl.courses))