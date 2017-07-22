require 'crawler_rocks'
require 'pry'
require 'iconv'
require 'json'

class NcutCourseCrawler

	DAYS = {
	'一' => '1',
	'二' => '2',
	'三' => '3',
	'四' => '4',
	'五' => '5',
	'六' => '6',
	'日' => '7'
	}

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil

		@year = year
    	@term = term
    	#@post_url = "http://msd.ncut.edu.tw/wbcmsc/cmain.asp"
    	@update_progress_proc = update_progress
        @after_each_proc = after_each
        @ic = Iconv.new('utf-8//IGNORE', 'big5')
	end

	def courses
		@courses = []
		year = @year
		term = @term

		r = `curl "http://msd.ncut.edu.tw/wbcmsc/cdptgd.asp" -H "Cookie: __utmt=1; __utma=82590601.72128976.1440399078.1440399078.1440399078.1; __utmb=82590601.1.10.1440399078; __utmc=82590601; __utmz=82590601.1440399078.1.1.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not"%"20provided); sto-id-20480=AIEHIAIMFAAA; ASPSESSIONIDCQSARQCB=KOIMNKPAHGDEIELLEDMBKPOE" -H "Origin: http://msd.ncut.edu.tw" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-TW,zh;q=0.8,en-US;q=0.6,en;q=0.4" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: http://msd.ncut.edu.tw/wbcmsc/cdptgd.asp" -H "Connection: keep-alive" --data "dptcd=1150&gd=&schyy=#{year-1911}&smt=#{term}&action="%"BDT"%"A9w" --compressed`
		doc = Nokogiri::HTML(@ic.iconv(r))

		index_dep = doc.css('select[name="dptcd"] option')
		index_dep[1..-1].each do |department_select|
			department_code = department_select.text[0..3].to_s
			r = `curl "http://msd.ncut.edu.tw/wbcmsc/cdptgd.asp" -H "Cookie: __utmt=1; __utma=82590601.72128976.1440399078.1440399078.1440399078.1; __utmb=82590601.1.10.1440399078; __utmc=82590601; __utmz=82590601.1440399078.1.1.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not"%"20provided); sto-id-20480=AIEHIAIMFAAA; ASPSESSIONIDCQSARQCB=KOIMNKPAHGDEIELLEDMBKPOE" -H "Origin: http://msd.ncut.edu.tw" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-TW,zh;q=0.8,en-US;q=0.6,en;q=0.4" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: http://msd.ncut.edu.tw/wbcmsc/cdptgd.asp" -H "Connection: keep-alive" --data "dptcd=#{department_code}&gd=&schyy=#{year-1911}&smt=#{term}&action="%"BDT"%"A9w" --compressed`
			#binding.pry if department_code == "3120"
			print (index_dep.size-1).to_s + "/" + index_dep.index(department_select).to_s
			 
			doc = Nokogiri::HTML(@ic.iconv(r))
			deparment_name = doc.css('select[name="dptcd"] option[selected]').text
			
			doc.css('form[name="where"] table tbody tr')[0..-1].each do |row|
				datas = row.css('td')

				course_days = []
				course_periods = []
				course_locations = []

				if(datas[8].text.size > 1)
					course_T = datas[8].text.split(',')
					
					course_T[0..-1].each do |_class|
						tempCourse =_class.split /(?<days>.)(?<periods>\d\d-\d\d)(?<location>.*)/
						start_course = tempCourse[2][0..1].to_i
						end_course = tempCourse[2][3..4].to_i

						start_course.upto(end_course) do |_period|
						course_days << DAYS[tempCourse[1]]
						course_periods << _period.to_s
						course_locations << tempCourse[3]

						end
					end
				end

				course = {
					name: "#{datas[1].text.strip}",
					year: @year,
					term: @term,
					code: "#{@year}-#{@term}-#{datas[0].text.strip}",
					class_no: "#{datas[5].text.strip}",
					department: deparment_name,
					credits: "#{datas[2].text.strip}",
					lecturer: "#{datas[4].text.strip}",
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
		@courses
	end


end

cwl = NcutCourseCrawler.new(year: 2015, term: 1)
File.write('courses.json', JSON.pretty_generate(cwl.courses))