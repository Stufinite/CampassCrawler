require 'crawler_rocks'
require 'pry'
require 'iconv'
require 'json'

class MduCourseCrawler

	DEP = [
		'91',
		'91M',
		'33L',
		'22L',
		'32L',
		'40L',
		'30l',
		'35L',
		'39L',
		'23L',
		'27L',
		'34L',
		'26L',
		'24L',
		'20L',
		'28',
		'28D',
		'28A',
		'08',
		'08D',
		'60H',
		'33',
		'33A',
		'29',
		'29A',
		'14',
		'03F',
		'22',
		'03',
		'03D',
		'12',
		'38',
		'06H',
		'38A',
		'06',
		'09',
		'32',
		'32A',
		'31',
		'31A',
		'02',
		'02D',
		'40',
		'11',
		'19',
		'30',
		'30D',
		'30H',
		'30A',
		'90',
		'90B',
		'90P',
		'90M',
		'23E',
		'32E',
		'30E',
		'24E',
		'35',
		'35A',
		'23W',
		'29V',
		'22V',
		'38V',
		'31V',
		'40V',
		'35V',
		'23V',
		'27V',
		'26V',
		'24V',
		'05',
		'05D',
		'05P',
		'88',
		'60T',
		'94',
		'94B',
		'94M',
		'04',
		'04H',
		'04D',
		'60',
		'25',
		'25A',
		'39',
		'28B',
		'33B',
		'29B',
		'22B',
		'38B',
		'32B',
		'31B',
		'40B',
		'30B',
		'35B',
		'25B',
		'39B',
		'23B',
		'27B',
		'34B',
		'26B',
		'24B',
		'24W',
		'21B',
		'20B',
		'23',
		'23A',
		'07',
		'07D',
		'38S',
		'24S',
		'83',
		'37',
		'37A',
		'92',
		'92B',
		'92M',
		'03A',
		'27',
		'27A',
		'13',
		'34',
		'34A',
		'36',
		'26',
		'26H',
		'26A',
		'01',
		'01D',
		'01A',
		'01F',
		'01H',
		'24',
		'24D',
		'24H',
		'24A',
		'15',
		'95',
		'95B',
		'21',
		'21A',
		'93',
		'93B',
		'93M',
		'20',
		'20A',
		'10',
	]

	GRADE =[
		'1',
		'2',
		'3',
		'4',
		'5',
		'6',
	]

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil
		@year = year
    	@term = term
    	@update_progress_proc = update_progress
    	@after_each_proc = after_each
	end

	def courses
		@courses = []
		year = @year
		term = @term
		DEP.each do |dep|
			GRADE.each do |gra|
				puts "grade: " + GRADE.size.to_s + "/" +(GRADE.index(gra)+1).to_s + " , dep:"+DEP.size.to_s + "/" + (DEP.index(dep)+1).to_s
				r = `curl "http://isc.mdu.edu.tw/net/cosinfo/show_class_cos_table.asp?mDept_No=#{dep}&mDept_year=#{gra}&mSmtr=#{year-1911}#{term}&mTchName=" -H "Accept-Encoding: gzip, deflate, sdch" -H "Accept-Language: zh-TW,zh;q=0.8,en-US;q=0.6,en;q=0.4" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.155 Safari/537.36" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Referer: http://isc.mdu.edu.tw/net/cosinfo/deptlist.asp" -H "Cookie: ASPSESSIONIDSABDCCDC=GNODMDNBAHOABENNFCFEIKIK; _ga=GA1.3.1067074322.1439970304" -H "Connection: keep-alive" --compressed`
				doc = Nokogiri::HTML(r)

				if(doc.text.strip != "無授課資料~~！！")
					index = doc.css('form[name="thisForm"] table')[1].css('tr')
					index[2..-1].each do |row|
						datas = row.css('td')

						course_days = []
					    course_periods = []
					    course_locations = []

					    datas[13..19].each do |days|
					    	if(days.text.to_s.size > 1)
					    		course_T = days.text.split /(?<per>\d)(?<loc>\(.\d\d\d\))/
					    		1.upto((course_T.size)/3) do |periods|
					    			course_days << (datas.index(days).to_i-12).to_s
					    			course_periods << course_T[3*periods-2]
			    					course_locations << course_T[3*periods-1]
					    		end
					    	end
					    end

					    course = {
						  name: "#{datas[2].text.strip}",
						  year: @year,
						  term: @term,
						  code: "#{@year}-#{@term}-#{datas[1].text.strip}",
						  _class: "#{datas[3].text.strip}",
						  credits: "#{datas[6].text.strip}",
						  lecturer: "#{datas[12].text.strip}",
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

cwl = MduCourseCrawler.new(year: 2015, term: 1)
File.write('courses.json', JSON.pretty_generate(cwl.courses))