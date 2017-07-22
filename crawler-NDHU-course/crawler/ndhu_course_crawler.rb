require 'crawler_rocks'
require 'json'
require 'iconv'
require 'pry'

class NdhuCourseCrawler

    DAYS = { "一" => 1,"二" => 2,"三" => 3, "四" => 4, "五" => 5, "六" => 6,"日" => 7,}

  def initialize  year: nil, term: nil, update_progress: nil, after_each: nil # initialize 94建構子
    @year = year
    @term = term
    @query_url = "http://sys.ndhu.edu.tw/aa/class/course/Default.aspx"
    # @ic = Iconv.new('utf-8//translit//IGNORE', 'big-5')
    #@result_url = "https://web085003.adm.ncyu.edu.tw/pub_depta2.aspx"

    @after_each_proc = after_each
    @update_progress_proc = update_progress
  end

  def courses
    @courses = []
    # start write your crawler here:
    r = RestClient.get @query_url
    doc = Nokogiri::HTML(r)

    @cookies = r.cookies


    colleges_hash = Hash[ 
      doc.css('select[name="ddlCOLLEGE"] option')[1..-1].map{|option| [option[:value], option.content]}
    ]

    colleges_hash.keys[0..-1].each do |college_post_value|
       
      #collge_name = colleges_hash[college_post_value]
      dept_post_value,degree_post_value = 'NA'
      doc = web_post(doc,college_post_value,dept_post_value,degree_post_value)


      dept_hash = Hash[ 
        doc.css('select[name="ddlDEP"] option')[0..-1].map{|option| [option[:value], option.content]}
      ]

      dept_hash.each_with_index do |(dept_post_value,dept_name), dep_index|
        print "#{dep_index+1} / #{dept_hash.keys.count}: #{dept_name}\n"

        degree_post_value = 'NA'
        doc = web_post(doc,college_post_value,dept_post_value,degree_post_value)


        degree_hash = Hash[ 
          doc.css('select[name="ddlCLASS"] option')[0..-1].map{|option| [option[:value], option.content]}
        ]

        degree_hash.each do |degree_post_value,degree_name|
      
          doc = web_post(doc,college_post_value,dept_post_value,degree_post_value,check:'查詢(中文)')

          doc.css('#GridView1 tr:not(:first-child)').each do |row|
            columns = row.css('td')
            next if columns[5].nil?

            period_loc = columns[13].text.strip
            regl = /\/(?<loc>[^\/]+)/
            period_loc.scan(regl)

            course_locations = [] 
            course_locations.concat(period_loc.scan(regl).map(&:first)) unless period_loc.strip.empty?
            course_locations.map{|course_locations|course_locations+columns[0]}
            #concat 陣列串連陣列，字串串連字串
            #&自己 :first 用自己呼叫. first 這個方法

            period_time_data = columns[3].text.strip
            temp = period_time_data.split("/")
            temp.delete("")
            days = temp.map.with_index{|temp,i|temp[0]}
            
            course_days = []
            course_periods = []

            temp.each_with_index do |content,index|
              course_days << DAYS[days[index]]
            end

            course_periods = temp.map.with_index{|temp,i|temp[1..-1]}

            course = {
              department: columns[21] && columns[21].text,
              name: columns[5] && columns[5].text,
              year: @year,
              term: @term,
              code: "#{@year}-#{@term}-#{columns[4].text.strip}",
              credits: columns[11].text,
              lecturer:columns[12].text.strip,
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
            puts "test1"
          end

          doc.css('#GridView2 tr:not(:first-child)').each do |row|
            columns = row.css('td')
            next if columns[6].nil?

            period_loc = columns[14].text.strip
            regl = /\/(?<loc>[^\/]+)/
            period_loc.scan(regl)

            course_locations = [] 
            course_locations.concat(period_loc.scan(regl).map(&:first)) unless period_loc.strip.empty?
            course_locations.map{|course_locations|course_locations+columns[0]}
            
            period_time_data = columns[4].text.strip
            temp = period_time_data.split("/")
            temp.delete("")
            days = temp.map.with_index{|temp,i|temp[0]}
            
            course_days = []
            course_periods = []

            temp.each_with_index do |content,index|
              course_days << DAYS[days[index]]
            end

            course_periods = temp.map.with_index{|temp,i|temp[1..-1]}

            course = {
              department: columns[0].text,
              name: columns[6].text,
              year: @year,
              term: @term,
              code: "#{@year}-#{@term}-#{columns[5].text.strip}",
              credits: columns[12].text,
              lecturer:columns[13].text.strip,
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
            puts "test2"
          end
        end #degree
     
      #@after_each_proc.call(course: course) if @after_each_proc
      # end each row

      # table = doc.css('table[border="1"][align="center"][cellpadding="1"][cellspacing="0"][width="99%"]')[0]

      # rows = table.css('tr:not(:first-child)')
      # rows.each do |row|
      #   table_datas = row.css('td')

      #   course = {
      #     department_code: table_datas[2].text,
      #     # name: aaa,
      #     # code: aaa,
      #   }

      #   @courses << course
      # end
      # File.write("temp/#{dept_value}.html", r)
      # end each dept_values

    # binding.pry
    # puts "hello"
           
      end # dept
     
    end
    @courses
  end # end course method
  
  def view_state doc
    Hash[doc.css('input[type="hidden"]').map{|input| [input[:name], input[:value]]}]    
  end

  def web_post doc, college_post_value,dept_post_value, degree_post_value, check:nil
    r = RestClient.post(@query_url, view_state(doc).merge({
      "ddlYEAR" => '104/1',
      "ddlCOLLEGE" => college_post_value,
      "ddlDEP" => dept_post_value,
      "ddlCLASS" => degree_post_value,
      "ddlDAY" => '0',
      "ddlTIME" => '0',
      "ddlAREA" => '0',
      "ddlROOM" => 'NA',
      "ddlSENG" => '0',
      "ddlCORE" => '0',
      "ddlSSTATUS" => '0',
      "btnCourse" => check,
    }), cookies: @cookies)
    doc = Nokogiri::HTML(r)
    
  end
end


# crawler = NdhuCourseCrawler.new(year: 2015, term: 1)
# File.write('ndhu_courses.json', JSON.pretty_generate(crawler.courses()))
