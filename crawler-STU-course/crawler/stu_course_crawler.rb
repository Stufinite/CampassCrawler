require 'nokogiri'
require 'httpclient'
require 'pry'
require 'json'

require 'thread'
require 'thwait'

class StuCourseCrawler

	DAY = {
		'一' => 1,
		'二' => 2,
		'三' => 3,
		'四' => 4,
		'五' => 5,
		'六' => 6,
		'日' => 7,
	}

	PERIOD = {
		'1' => 1,
		'2' => 2,
		'3' => 3,
		'4' => 4,
		'5' => 5,
		'6' => 6,
		'7' => 7,
		'8' => 8,
		'9' => 9,
		'A' => 10,
		'B' => 11,
		'C' => 12,
		'D' => 13,
		'午' => '午',
		'傍' => '傍'
	}

	DEPARTMENT = {
		"AAJ" => 'AAJ-通識教育學院',
		"AAU" => 'AAU-通識教育學院',
		"ADG" => 'ADG-應用設計研究所',
		"AEU" => 'AEU-車用電子學士學位學程',
		"ALU" => 'ALU-應用外語系',
		"AMU" => 'AMU-藝術管理與藝術經紀學位學程',
		"ASU" => 'ASU-通識教育學院',
		"BAU" => 'BAU-企業管理系',
		"BAJ" => 'BAJ-企業管理科',
		"BBU" => 'BBU-管理學院',
		"BMG" => 'BMG-資訊學院',
		"BMU" => 'BMU-資訊學院',
		"CCG" => 'CCG-兒童與家庭服務系碩士班',
		"CCU" => 'CCU-兒童與家庭服務系',
		"CCJ" => 'CCJ-兒童與家庭服務科',
		"COG" => 'COG-電腦與通訊系碩士班',
		"COU" => 'COU-電腦與通訊系',
		"DEU" => 'DEU-設計學院',
		"DGU" => 'DGU-動畫與遊戲設計系',
		"FDJ" => 'FDJ-流行設計科',
		"FDU" => 'FDU-流行設計系',
		"HCG" => 'HCG-建築與室內設計研究所',
		"HCU" => 'HCU-建築與環境設計系',
		"HMU" => 'HMU-餐旅管理學位學程',
		# "HSG" => 'HSG-人類性學研究所博士班',
		"HSG" => 'HSG-人類性學研究所',
		"IBU" => 'IBU-國際企業與貿易系',
		"IDU" => 'IDU-室內設計系',
		"IEU" => 'IEU-資訊工程系',
		"IEG" => 'IEG-資訊工程系碩士班',
		"IMG" => 'IMG-資訊管理系碩士班',
		"IMU" => 'IMU-資訊管理系',
		"LRU" => 'LRU-休閒與觀光管理系',
		"LRJ" => 'LRJ-休閒與觀光管理科',
		"MAJ" => 'MAJ-運籌管理科',
		"MAU" => 'MAU-運籌管理系',
		"MBG" => 'MBG-經營管理研究所',
		"MEU" => 'MEU-會議展覽與國際行銷學位學程',
		"MIG" => 'MIG-管理學院碩士班',
		"MMJ" => 'MMJ-行銷管理科',
		"MMU" => 'MMU-行銷管理系',
		"MTG" => 'MTG-會展管理與貿易行銷碩士學位學程',
		"OSU" => 'OSU-校外系所',
		"PAU" => 'PAU-表演藝術系',
		"PDG" => 'PDG-生活產品設計系碩士班',
		"PDU" => 'PDU-生活產品設計系',
		"RSG" => 'RSG-金融系碩士班',
		"RSU" => 'RSU-金融系',
		"SAU" => 'SAU-應用社會學院',
		"SMU" => 'SMU-休閒遊憩與運動管理系',
		"SWU" => 'SWU-社會工作學士學位學程',
		"TEU" => 'TEU-師資培育中心',
		"VDU" => 'VDU-視覺傳達設計系',
		"VDG" => 'VDG-視覺傳達設計系碩士班',
		"ZZU" => 'ZZU-通識教育學院',
	}
	
	def initialize	year:nil, term:nil, update_progress: nil, after_each: nil
		@year = year
		@term = term
		@update_progress = update_progress
    	@after_each = after_each
	end #end init

	def courses
		@courses = []
		@threads = []

		res = clnt.post("https://info.stu.edu.tw/ACA/student/QueryAGECourse/index.asp",{
				yr: "#{@year-1911}#{@term}",
				dep: '0',
				coursetype: '',
				ref1: '',
				admissionType: '0',
				credit: '0',
				re: '0',
				grd: '0',
				prog: '0',
				ecourse: '0',
				eng: '0',
				forcourse: '0',
				coursename: '',
				teachername: ''
			})

		@courses_list = Nokogiri::HTML(res.body)
		@courses_list_trs = @courses_list.css('table[@class="sortable"]').css('tr')[1..-1]

		@courses_list_trs.each_with_index do | row, index|
	      sleep(1) until (
	        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
	        @threads.count < 20 ;
	      )

	      @threads << Thread.new do
  	        table_data = row.css('td')

  	        course_general_code = table_data[0].text.strip
  	        course_name = table_data[1].text.strip
  	        course_lecturer = table_data[3].text.strip
  	        course_time_1 = table_data[4].text.strip
  	        course_time_2 = table_data[7].text.strip
  	        course_location_1 = table_data[5].text.strip
  	        course_location_2 = table_data[8].text.strip
  	        course_required = table_data[13].text.strip
  	        course_credits = table_data[14].text.strip

  	        course_department_code = course_general_code.match(/(?<code>^.{0,3})/)
  	        course_department_code = course_department_code[:code]
  	        course_department = DEPARTMENT[course_department_code]
  	        if table_data[6] != ""
  	        	course_lecturer = "#{course_lecturer}, table_data[6]"
  	        end

  	        course_day_period_1 = []
  	        course_day_period_2 = []
 

 			isTime1Empty = false
 			isLocation1Empty = false
  	        isTime2Empty = false
        	isLocation2Empty = false

        	if course_time_1 == ""
        		isTime1Empty = true
        	end
        	if course_location_1 ==""
        		isLocation1Empty == true
        	end
  	        if course_time_2 == ""
  	        	isTime2Empty = true
  	        end
  	        if course_location_2 == ""
  	        	isLocation2Empty = true
  	        end

  	        course_days = []
  	        course_periods = [] 
  	        course_locations = []

  	        #沒有時間的課, 不進入if, e.g.,專題
  	        if isTime1Empty == false
	  	        course_time_1.scan(/[一二三四五六日].?/).each do |i|
	  	        	course_day_period_1 << i.match(/(?<day>[一二三四五六日])(?<period>.?)/)
	  	        end #end each

	  	        #有time2的課, 解構string
	  	        if isTime2Empty == false
		  	        course_time_2 scan(/[一二三四五六日].?/).each do |i|
		  	        	course_day_period_2 << i.match(/(?<day>[一二三四五六日])(?<period>.?)/)
		  	        end #end each 
		  	    end #end if 

		  	    #If Location1 isn't empty
	  	       	if isLocation1Empty == false
		  	        course_day_period_1.each do |i|
		  	        	course_days << DAY[i[:day]]
		  	        	course_periods << PERIOD[i[:period]]
		  	        	course_locations << course_location_1
		  	        end #end each
		  	    #If Location1 is empty, location = Location2.
		  	    else
		  	    	course_day_period_1.each do |i|
		  	        	course_days << DAY[i[:day]]
		  	        	course_periods << PERIOD[i[:period]]
		  	        	course_locations << course_location_2
		  	        end #end each
		  	    end # end isLocation1Empty


	  	        if isLocation2Empty == false && isLocation1Empty == false
	  	        	#If Location2 isn't empty and Time2 isn't empty
	  	        	if isTime2Empty == false
				        course_day_period_2.each do |i|
				        	course_days << DAY[i[:day]]
				        	course_periods << PERIOD[i[:period]]
				        	course_locations << course_location_2
				        end #end each
			    	end #end if  

			    #If Location2 is empty and Time2 isn't empty.
			    elsif isTime2Empty == false
			        course_day_period_2.each do |i|
			        	course_days << DAY[i[:day]]
			        	course_periods << PERIOD[i[:period]]
			        	course_locations << course_location_1
			        end #end each	
			    end #end if 
			end #end isTime1Empty

		    course = {
	          :year => @year,    # 西元年
	          :term => @term,    # 學期 (第一學期=1，第二學期=2)
	          :name => course_name,    # 課程名稱
	          :lecturer => course_lecturer,    # 授課教師
	          :credits => course_credits,    # 學分數
	          :code => "#{@year}-#{@term}-#{course_general_code}",
	          :general_code => course_general_code,    # 選課代碼
	          :required => course_required.include?('必'),    # 必修或選修
	          :department => course_department,    # 開課系所
	          :department_code => course_department_code,

	          :day_1 => course_days[0],
	          :day_2 => course_days[1],
	          :day_3 => course_days[2],
	          :day_4 => course_days[3],
	          :day_5 => course_days[4],
	          :day_6 => course_days[5],
	          :day_7 => course_days[6],
	          :day_8 => course_days[7],
	          :day_9 => course_days[8],

	          :period_1 => course_periods[0].to_i,
	          :period_2 => course_periods[1].to_i,
	          :period_3 => course_periods[2].to_i,
	          :period_4 => course_periods[3].to_i,
	          :period_5 => course_periods[4].to_i,
	          :period_6 => course_periods[5].to_i,
	          :period_7 => course_periods[6].to_i,
	          :period_8 => course_periods[7].to_i,
	          :period_9 => course_periods[8].to_i,

	          :location_1 => course_locations[0],
	          :location_2 => course_locations[1],
	          :location_3 => course_locations[2],
	          :location_4 => course_locations[3],
	          :location_5 => course_locations[4],
	          :location_6 => course_locations[5],
	          :location_7 => course_locations[6],
	          :location_8 => course_locations[7],
	          :location_9 => course_locations[8]
	        }
	        @after_each_proc.call(course: course) if @after_each_proc
		    @courses << course		    
	      end #end thread
	    end #end each tr
        ThreadsWait.all_waits(*@threads)
        @courses
	end #end courses

	def clnt
	    @http_client ||= HTTPClient.new
	end #end clnt
end #end class