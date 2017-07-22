require 'json'
require 'crawler_rocks'
require 'pry'

require 'thread'
require 'thwait'

require 'digest'

class NtnuCourseCrawler

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7,
  }

  NTUST_DAYS = {
    # 118 style
    "M" => 1,
    "F" => 5,
    "T" => 2,
    "S" => 6,
    "W" => 3,
    "U" => 7,
    "R" => 4
  }

  PERIODS = {
    "0" => 1,
    "1" => 2,
    "2" => 3,
    "3" => 4,
    "4" => 5,
    "5" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "9" => 10,
    "10" => 11,
    "A" => 12,
    "B" => 13,
    "C" => 14,
    "D" => 15,
    "X" => 11,
  }

  DEPARTMENTS = {
    "GU" => "通識",
    "CU" => "共同科",
    "MT" => "軍訓室",
    "EU" => "師資職前教育專業課程",
    "PE" => "普通體育",
    "VS" => "服務學習",
    "9UAA" => "校際學士班(臺大)",
    "9MAA" => "校際碩士班(臺大)",
    "9DAA" => "校際博士班(臺大)",
    "9UAB" => "校際學士班(臺科大)",
    "9MAB" => "校際碩士班(臺科大)",
    "9DAB" => "校際博士班(臺科大)",
    "E" => "教育學院",
    "EU00" => "教育系",
    "EM00" => "教育碩",
    "ED00" => "教育博",
    "SA00" => "教育輔",
    "EU01" => "心輔系",
    "EM01" => "心輔碩",
    "ED01" => "心輔博",
    "SA01" => "心輔輔",
    "EU02" => "社教系",
    "EM02" => "社教碩",
    "ED02" => "社教博",
    "SA02" => "社教輔",
    "EM03" => "課教碩",
    "ED03" => "課教博",
    "EU05" => "衛教系",
    "EM05" => "衛教碩",
    "ED05" => "衛教博",
    "SA05" => "衛教輔",
    "EU06" => "人發系",
    "EM06" => "人發碩",
    "ED06" => "人發博",
    "SA06" => "人發輔",
    "EU07" => "公領系",
    "EM07" => "公領碩",
    "ED07" => "公領博",
    "SA07" => "公領輔",
    "EM08" => "資訊碩",
    "ED08" => "資訊博",
    "SA08" => "資訊輔",
    "EU09" => "特教系",
    "EM09" => "特教碩",
    "ED09" => "特教博",
    "SA09" => "特教輔",
    "EM15" => "圖資碩",
    "ED15" => "圖資博",
    "EM16" => "教政碩",
    "EM17" => "復諮碩",
    "L" => "文學院",
    "LU20" => "國文系",
    "LM20" => "國文碩",
    "LD20" => "國文博",
    "SA20" => "國文輔",
    "LU21" => "英語系",
    "LM21" => "英語碩",
    "LD21" => "英語博",
    "SA21" => "英語輔",
    "LU22" => "歷史系",
    "LM22" => "歷史碩",
    "LD22" => "歷史博",
    "SA22" => "歷史輔",
    "LU23" => "地理系",
    "LM23" => "地理碩",
    "LD23" => "地理博",
    "SA23" => "地理輔",
    "LM25" => "翻譯碩",
    "LD25" => "翻譯博",
    "LU26" => "臺文系",
    "LM26" => "臺文碩",
    "LD26" => "臺文博",
    "LM27" => "臺史碩",
    "S" => "理學院",
    "SU40" => "數學系",
    "SM40" => "數學碩",
    "SD40" => "數學博",
    "SA40" => "數學輔",
    "SU41" => "物理系",
    "SM41" => "物理碩",
    "SD41" => "物理博",
    "SA41" => "物理輔",
    "SU42" => "化學系",
    "SM42" => "化學碩",
    "SD42" => "化學博",
    "SA42" => "化學輔",
    "SU43" => "生科系",
    "SM43" => "生科碩",
    "SD43" => "生科博",
    "SA43" => "生科輔",
    "SU44" => "地科系",
    "SM44" => "地科碩",
    "SD44" => "地科博",
    "SA44" => "地科輔",
    "SM45" => "科教碩",
    "SD45" => "科教博",
    "SM46" => "環教碩",
    "SD46" => "環教博",
    "SU47" => "資工系",
    "SM47" => "資工碩",
    "SD47" => "資工博",
    "SM48" => "光電碩",
    "SD48" => "光電博",
    "SM49" => "海環碩",
    "SD50" => "生物多樣學位學程",
    "T" => "藝術學院",
    "TU60" => "美術系",
    "TM60" => "美術碩",
    "TD60" => "美術博",
    "TM67" => "藝史碩",
    "TU68" => "設計系",
    "TM68" => "設計碩",
    "TD68" => "設計博",
    "H" => "科技學院",
    "HU70" => "工教系",
    "HM70" => "工教碩",
    "HD70" => "工教博",
    "HU71" => "科技系",
    "HM71" => "科技碩",
    "HD71" => "科技博",
    "SA71" => "科技輔",
    "HU72" => "圖傳系",
    "HM72" => "圖傳碩",
    "HU73" => "機電系",
    "HM73" => "機電碩",
    "HD73" => "機電博",
    "HU75" => "電機系",
    "HM75" => "電機碩",
    "A" => "運休學院",
    "AU30" => "體育系",
    "AM30" => "體育碩",
    "AD30" => "體育博",
    "AM31" => "休旅碩",
    "AD31" => "休旅博",
    "AU32" => "競技系",
    "AM32" => "競技碩",
    "I" => "國社學院",
    "IM82" => "歐文碩",
    "IU83" => "東亞系",
    "IM83" => "東亞碩",
    "IU84" => "華語系",
    "IM84" => "華語碩",
    "ID84" => "華語博",
    "IU85" => "應華系",
    "IM85" => "應華碩",
    "IM86" => "人資碩",
    "IM87" => "政治碩",
    "ID87" => "政治博",
    "IM88" => "大傳碩",
    "IM89" => "社工碩",
    "M" => "音樂學院",
    "MU90" => "音樂系",
    "MM90" => "音樂碩",
    "MD90" => "音樂博",
    "MM91" => "民音碩",
    "MU92" => "表演學位學程",
    "MM92" => "表演碩",
    "MM93" => "流行碩",
    "O" => "管理學院",
    "OM55" => "管理碩",
    "OM56" => "全營碩",
    "OU57" => "企管學位學程",
    "ZU80" => "創新管理學程",
    "ZU81" => "生資技術學程",
    "ZU82" => "光電學程",
    "ZU83" => "基礎管理學程",
    "ZU84" => "財金學程",
    "ZU85" => "數位內容學程",
    "ZU86" => "華語教學學程",
    "ZU87" => "文化創意學程",
    "ZU88" => "影音藝術學程",
    "ZU89" => "環境監測學程",
    "ZU90" => "生態藝術學程",
    "ZU91" => "音樂典藏學程",
    "ZU92" => "榮譽英語學程",
    "ZU93" => "法語學程",
    "ZU94" => "文學創作學程",
    "ZU95" => "亞太研究學程",
    "ZU96" => "德語學程",
    "ZU97" => "日語學程",
    "ZU98" => "高齡健康促進學程",
    "ZU99" => "光電藝術學程",
    "ZU9A" => "區域學程",
    "ZU9B" => "空間學程",
    "ZU9C" => "學校心理學學程",
    "ZU9D" => "應史學程",
    "ZU9E" => "社會政治大傳學程",
    "ZU9F" => "技職教育學程",
    "ZU9G" => "復諮學程",
    "ZU9H" => "高科技金融學程",
    "ZU9I" => "文創藝術學程",
    "ZU9J" => "設計實務學程",
    "ZU9K" => "數位評量調查學程",
    "ZU9L" => "生態藝術科普學程",
    "ZU9M" => "服務管理學程"
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil
    @url = "http://courseap.itc.ntnu.edu.tw/acadmOpenCourse/CofopdlCtrl"
    @syllabus_url = "http://courseap.itc.ntnu.edu.tw/acadmOpenCourse/SyllabusCtrl"

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each
  end

  def courses
    @courses = []

    done_departments_count = 0

    @threads = []

    DEPARTMENTS.keys.each_with_index do |dep_code, index|
      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < (ENV['MAX_THREADS'] || 25)
      )

      @threads << Thread.new do
        # puts "#{dep_code}, #{index}"
        begin
          respond = RestClient.get @url, params: url_params_for_department(department: dep_code, year: @year-1911, term: @term)
          respond = JSON.parse(respond.to_s)
        rescue Exception => e
          print "Error on #{dep_code}! #{e}! retry later...\n"
          sleep(1)
          redo
        end

        course_detail_threads = []

        @courses.concat(respond['List'])
        # respond['List'].each do |course|

          # course_detail_threads << Thread.new do

            # begin
            #   respond = RestClient.get @syllabus_url, :params => url_params_for_course(course)
            #   html = Nokogiri::HTML(respond.to_s)
            #   book_row = html.css('tr:contains("參考書目") css')
            #   course[:textbook] = book_row.last.text unless book_row.empty?
            # rescue Exception => e
            #   course[:textbook] = nil
            # end

            # @courses << course
          # end
        # end

        # ThreadsWait.all_waits(*course_detail_threads)

        done_departments_count += 1
        print "(#{done_departments_count}/#{DEPARTMENTS.count}) done #{dep_code}\n"
      end # end Thread
    end
    ThreadsWait.all_waits(*@threads)

    # if done_departments_count == departments.count

    #   File.open('courses.json', 'w') { |f| f.write(JSON.pretty_generate(normalize(@courses))) }
    # end

    normalize(@courses)
  end

  private
    def url_params_for_department(department: nil, year: nil, term: nil, language: 'chinese')
      {
        acadmYear: year,
        acadmTerm: term,
        deptCode: department,
        language: language,
        action: 'showGrid',
        start: 0,
        limit: 99999,
        page: 1
      }
    end

    def url_params_for_course(c)
      {
        year: c["acadm_year"],
        term: c["acadm_term"],
        courseCode: c["course_code"],
        courseGroup: c["course_group"],
        formS: c["form_s"],
        classes1: c["classes"],
        deptCode: c["dept_code"],
        deptGroup: c["dept_group"],
        language2: ""
      }
    end

    def current_year
      (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
    end

    def current_term
      (Time.now.month.between?(2, 7) ? 2 : 1)
    end

    def normalize(courses)
      print "start normalize course\n"
      new_courses = []
      @update_threads = []

      courses.each do |course|

        course_days = []
        course_periods = []
        course_locations = []

        if course["time_inf"] && course["time_inf"].match(/(?<d>[#{DAYS.keys.join}])(?<p>[#{PERIODS.keys.join}]+)；(?<loc>.+)。/)
          # course["dept_chiabbr"].include?('臺大')
          # 二3；請洽系所辦。五34；請洽系所辦。
          course["time_inf"].scan(/(?<d>[#{DAYS.keys.join}])(?<p>[#{PERIODS.keys.join}]+)；(?<loc>.+)。/).each do |m|

            m[1].split('').each do |p|
              course_days << DAYS[m[0]]
              course_periods << PERIODS[p]
              course_locations << m[2]
            end
          end

        elsif course["time_inf"] && course["time_inf"].match(/(?<d>[#{NTUST_DAYS.keys.join}])(?<p>\d)\((?<loc>.+)\)/)
          # course["dept_chiabbr"].include?('臺科大')
          # R2(RB-707)、R3(RB-707)、R4(RB-707) 多麼熟悉！
          course["time_inf"].scan(/(?<d>[#{NTUST_DAYS.keys.join}])(?<p>\d)\((?<loc>.+)\)/).each do |m|
            course_days << NTUST_DAYS[m[0]]
            course_periods << PERIODS[m[1]]
            course_locations << m[2]
          end

        else
          # course["time_inf"] = '一 9-10 本部 音樂系演奏廳,五 9-10 本部 音樂系演奏廳,'
          course["time_inf"] && course["time_inf"].split(',').each do |time_info|
            time_info.match(/(?<d>[#{DAYS.keys.join}]) (?<p>[\d\-#{PERIODS.keys.join}]+) (?<loc>.+)/) do |m|
              if !m[:p].include?('-')
                course_days << DAYS[m[:d]]
                course_periods << PERIODS[p]
                course_locations << m[:loc]
              else
                ps = m[:p].split('-')
                _start = PERIODS[ps[0]]
                _end = PERIODS[ps[1]]
                (_start.._end).each do|p|
                  course_days << DAYS[m[:d]]
                  course_periods << p
                  course_locations << m[:loc]
                end
              end # end if
            end
          end
        end # end parse time_loc

        lec_md5 = Digest::MD5.hexdigest(course["teacher"])
        general_code = "#{course["course_code"]}-#{lec_md5[0..4]}#{lec_md5[-5..-1]}"
        # 也許 code 也要抽掉 serial_no 改成 general_code 這樣了......

        course = {
          year: course["acadm_year"].to_i+1911,
          term: course["acadm_term"].to_i,
          name: course["chn_name"],
          code: "#{course["acadm_year"]}-#{course["acadm_term"]}-#{course["course_code"]}-#{course["serial_no"]}",
          general_code: course["serial_no"],
          credits: course["credit"].to_i,
          department: course["dept_chiabbr"],
          department_code: course["dept_code"],
          required: course["option_code"] == '必',
          lecturer: course["teacher"],
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
        new_courses << course

        sleep(1) until (
          @update_threads.delete_if { |t| !t.status };  # remove dead (ended) threads
          @update_threads.count < (ENV['MAX_THREADS'] || 30)
        )
        @update_threads << Thread.new do
          @after_each_proc.call(course: course) if @after_each_proc
        end
      end
      ThreadsWait.all_waits(*@update_threads)

      new_courses
    end
end

# cc = NtnuCourseCrawler.new(year: 2015, term: 1)
# File.write('ntnu_courses.json', JSON.pretty_generate(cc.courses))
