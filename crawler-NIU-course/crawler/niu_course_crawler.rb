#test
require 'spreadsheet'
require 'crawler_rocks'
require 'json'
require 'iconv'
require 'pry'

class NiuCourseCrawler 

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil
		@year = year
		@term = term
		@query = "https://acade.niu.edu.tw/NIU/outside.aspx?mainPage=LwBBAHAAcABsAGkAYwBhAHQAaQBvAG4ALwBUAEsARQAvAFQASwBFADUAMAAvAFQASwBFADUAMAAxADAAXwAwADEALgBhAHMAcAB4AD8AQQBZAEUAQQBSAFMATQBTAD0AMQAwADQAMQA="
		@post_url= "https://acade.niu.edu.tw/NIU//Application/TKE/TKE50/TKE5010_01.aspx?AYEARSMS=#{@year-1911}#{@term}"
		@ic = Iconv.new('utf-8//translit//IGNORE', 'utf-8')

    @after_each_proc = after_each
    @update_progress_proc = update_progress
	end

	def courses
		r = RestClient.get @query
		@cookies = r.cookies

		r = RestClient.get @post_url, cookies: @cookies
		doc = Nokogiri::HTML(r)

		view_state = Hash[ doc.css('input[type="hidden"]').map{|input| [input[:name], input[:value]]} ]

		response = RestClient.post @post_url, view_state.merge({
			"__EVENTTARGET" => 'DoExport',
			"OP" => 'OP1',
			"Q_WEEK" => '1',
			"CLASS" => '00',
			"radioButtonClass" => '0',
			"radioButtonQuery" => '0',
			"PC$PageSize" => '20',
			"PC$PageNo" => '1',
			"PC2$PageSize" => '20',
			"PC2$PageNo" => '1'
		}), cookies: @cookies

    Dir.mkdir('tmp') unless Dir.exist?('tmp')
    File.write('tmp/tmp.xls', response)

		@courses = []	

		Spreadsheet.client_encoding = 'UTF-8'
		book = Spreadsheet.open 'tmp/tmp.xls'

		sheet1 = book.worksheet 0
		# sheet2 = book.worksheet 'Sheet1'

		sheet1.each_with_index 2 do |row,index|
			print "#{index+1}\n"

			# puts row[2]+index.to_s
			
			# 等一下要分割地點loc_temp
			
			time_temp = []
			time_temp2 = []
			loc_temp = []
			course_days = []
			course_periods = []
			course_locations = []

      time_temp = row[9].to_s
      time_temp2 = time_temp.split(",")
  
      # begin
      # rescue Exception => e
      # end
      loc_temp = row[10].split(",")
			time_temp2.each_with_index do |content,index|
				# puts index
				course_days << time_temp[index][0].to_s
				course_periods << time_temp[index][1..-1]
				course_locations << loc_temp[index]
			end


			# binding.pry


			course ={
				department: row[0].split(","),
				
				name: row[2],
				year: @year,
				term: @term,
				code: "#{@year}-#{@term}-#{row[1]}",
				credits: row[6],
				lecturer:row[8],
				required:row[7].include?('必'),
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
		end # sheet1 do
	end # end courses
end # class

# crawler = NiuCourseCrawler.new(year: 2015, term: 1)
# File.write('niu_courses.json', JSON:(crawler.courses()))
