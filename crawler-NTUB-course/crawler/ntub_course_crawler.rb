require 'pry'
require 'httpclient'
require 'nokogiri'
require 'json'
require 'iconv'

require 'thread'
require 'thwait'

class NtubCourseCrawler
	def initialize year:nil, term:nil, update_progress: nil, after_each: nil
		@year = year
		@term = term
	    @update_progress_proc = update_progress
	    @after_each_proc = after_each
	end #end initialize

	def courses
		@courses=[]
		@threads=[]

		res = clnt.get_content("http://ntcbadm.ntub.edu.tw/pub/TchSchedule_Search.aspx")

		ic = Iconv.new("utf-8//translit//IGNORE", "utf-8")
        doc = Nokogiri::HTML(res)

		viewstate = Hash[ doc.css('input[type="hidden"]').map{|inp| [ inp[:name], inp[:value] ]}]
		res = clnt.post("http://ntcbadm.ntub.edu.tw/pub/TchSchedule_Search.aspx",{
			'ScriptManager1': 'UpdatePanel3|btnSearch',
			'txtYears': @year-1911,
			'txtTerm': @term,
			'ddlEdu': '-1',
			'CosNamekeyWord': '',
			'__ASYNCPOST': 'false',
			'btnSearch': '查詢'
		}.merge(viewstate))

		@courses_list = Nokogiri::HTML(res.body)

		@courses_list_trs = @courses_list.css('table#bgBase').css('table')[2].css('tr')[2..50]

		@courses_list_trs.each do |row|
			sleep(1) until (
				@threads.delete_if { |t| !t.status };  # remove dead (ended) threads
				@threads.count < 20 ;
			)

			@threads << Thread.new do
        		table_data = row.css('td')

        		#
		        course_department = table_data[1].text.strip
		        course_index = table_data[2].text.strip
		        course_general_code = table_data[3].text.strip
		        course_name = table_data[4].text.strip
		        course_lecturer = table_data[5].text.strip
		        course_time_locations=table_data[6].text.strip
		        course_credits = table_data[7].text.strip.to_i
		        course_hours = table_data[8].text.strip.to_i
		        course_required = table_data[10].text.strip

		        #Split time and location
		        course_time_locations = course_time_locations.split('/')
		        course_time = course_time_locations[0].split(' ')

		        course_locations=[]
		        course_days = []
		        course_periods = []
		        course_time.each do |i|
		        	i = i.match(/(?<day>\d)(?<period>.*)/)
		        	course_days << i[:day]
		        	course_periods << i[:period]
		        	course_locations << course_time_locations[1]
		        end #end each

		        course = {

					:year => @year,    # 西元年
					:term => @term,    # 學期 (第一學期=1，第二學期=2)
					:name => course_name,    # 課程名稱
					:lecturer => course_lecturer,    # 授課教師
					:credits => course_lecturer,    # 學分數
					:code => "#{@year}-#{@term}-#{course_general_code}",
					:general_code => course_general_code,    # 選課代碼
					:required => course_required.include?('必'),    # 必修或選修
					:department => course_department,    # 開課系所

					:day_1 => course_days[0].to_i,
					:day_2 => course_days[1].to_i,
					:day_3 => course_days[2].to_i,
					:day_4 => course_days[3].to_i,
					:day_5 => course_days[4].to_i,
					:day_6 => course_days[5].to_i,
					:day_7 => course_days[6].to_i,
					:day_8 => course_days[7].to_i,
					:day_9 => course_days[8].to_i,

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
		end	#end each tr
	   	ThreadsWait.all_waits(*@threads)
    	@courses
	end #end courses

	def clnt
	    @http_client ||= HTTPClient.new
	end #end clnt
end #end class