require 'crawler_rocks'
require 'pry'
require 'iconv'
require 'json'

class FguCourseCrawler

	DAYS = {
	'一' => 1,
	'二' => 2,
	'三' => 3,
	'四' => 4,
	'五' => 5,
	'六' => 6,
	'日' => 7
	}

	DEP = [
	'000',  #選讀生
	'001',  #碩士學分生
	'002',  #進修生
	'003',  #交換學生
	'004',  #研究所校際選課
	'005',  #學士班校際選課
	'006',  #學士學分生
	'023',  #短期進修海外學生
	'211',  #中國文學與應用學系學士班
	'212',  #中國文學與應用學系碩士班
	'213',  #中國文學與應用學系博士班
	'214',  #中國文學與應用學系碩士在職專班
	'221',  #藝術學系學士班
	'222',  #藝術學研究所碩士班
	'232',  #生命與宗教學系碩士班生命學組
	'241',  #哲學系學士班
	'242',  #哲學系碩士班
	'251',  #生命與宗教學系學士班
	'252',  #生命與宗教學系碩士班宗教學組
	'256',  #宗教學研究所碩士班
	'261',  #歷史學系學士班
	'262',  #歷史學系碩士班
	'271',  #人類學系學士班
	'281',  #佛教學系學士班
	'282',  #佛教學系碩士班
	'283',  #佛教學系博士班
	'291',  #外國語文學系學士班
	'292',  #外國語文學系碩士班
	'311',  #未來與樂活產業學系學士班
	'316',  #未來與樂活產業學系生命學碩士班
	'317',  #未來與樂活產業學系宗教學碩士班
	'321',  #政治學系學士班
	'322',  #政治學系碩士班
	'331',  #資訊應用學系學士班
	'332',  #資訊應用學系碩士班
	'334',  #資訊應用學系碩士在職專班
	'341',  #應用經濟學系學士班
	'342',  #應用經濟學系碩士班
	'344',  #應用經濟學系碩士在職專班
	'351',  #社會學系學士班
	'352',  #社會學系碩士班
	'361',  #公共事務學系學士班
	'362',  #公共事務學系政策與行政管理碩士班
	'364',  #公共事務學系碩士在職專班
	'366',  #公共事務學系國際與兩岸事務碩士班
	'371',  #傳播學系學士班
	'372',  #傳播學系碩士班
	'374',  #傳播學系碩士在職專班
	'381',  #心理學系學士班
	'382',  #心理學系碩士班
	'391',  #管理學系學士班
	'392',  #管理學系碩士班
	'394',  #管理學系碩士在職專班
	'411',  #學習與數位科技學系學士班
	'412',  #學習與數位科技學系碩士班
	'422',  #社會教育學研究所碩士班
	'451',  #財務金融學系學士班
	'461',  #產品與媒體設計學系學士班
	'462',  #產品與媒體設計學系碩士班
	'471',  #文化資產與創意學系學士班
	'472',  #文化資產與創意學系碩士班
	'611',  #樂活生命文化學系學士班
	'612',  #樂活生命文化學系碩士班
	'621',  #國際與兩岸事務學系學士班
	'622',  #國際與兩岸事務學系碩士班
	'631',  #健康與創意素食產業學系學士班
	'A12',  #國學班
	'x00',  #校外選課
	'511',  #基本能力訓練學門
	'512',  #經典教育學門
	'513',  #文史哲學門
	'514',  #社會科學學門
	'515',  #自然與科技學門
	'516',  #生活美學學門
	'517',  #生命教育學門
	'518',  #人文與藝術學門
	'519',  #世界主要文明與文化學門
	'521',  #特殊學程
	'531',  #基本能力課群
	'532',  #涵養與強化課群
	'533',  #人文藝術課群
	'534',  #社會科學課群
	'535',  #自然科學課群
	'536',  #生命教育課群
	'537',  #生活教育課群
	'538',  #生涯教育課群
	'711',  #學程－非營利事業學程
	'712',  #學程－文化創意產業學程
	'713',  #學程－數位創意與多媒體科技學程
	'714',  #學程－生命事業學程
	'715',  #學程－宗教傳播學程
	'716',  #學程－觀光旅遊學程
	'200',  #人文學院
	'300',  #社會科學暨管理學院
	'400',  #創意與科技學院
	'500',  #通識課程
	'600',  #佛教學院
	'640',  #樂活產業學院
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


		DEP.each do |department|
			puts "Department: " + DEP.size.to_s + "/" + (DEP.index(department)+1).to_s
			@url = "http://selcourse2.fgu.edu.tw/course_plan/cs_cont_all.aspx?in_years=#{year-1911}&in_semes=#{term}&in_depid="+department+"&out="
			r = RestClient.get @url
			doc = Nokogiri::HTML(r)

			if doc.css('body table[id="GridView_new"]').css('tr').size > 0 #nothing in the block
			#begin
			#rescue Exception => e
			#	next
			#end
					doc.css('body table[id="GridView_new"]').css('tr')[1..-1].each do |row|
					datas = row.css('td')

					course_days = []
		    		course_periods = []
		    		course_locations = []
		    		time_loc_regex = /(?<day>[一二三四五六日])\.(?<period>(\d{0,2}\,?)+)\((?<loc>.+)\)/
		    		datas[10].text.strip.scan(time_loc_regex).each do |array|
		    		course_days << DAYS[array[0]]
    				course_periods.concat array[1].split(',').map(&:to_i)
    				course_locations << array[2]
    				end


					course = {
					  	name: "#{datas[3].text.strip}",
						year: @year,
						term: @term,
						code: "#{@year}-#{@term}-"+ "#{datas[1].text.strip}",
						credits: "#{datas[5].text[0]}",
						grade: "#{datas[7].text.strip}",
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

cwl = FguCourseCrawler.new(year: 2015, term: 1)
File.write('courses.json', JSON.pretty_generate(cwl.courses))