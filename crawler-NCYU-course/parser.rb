require 'nokogiri'
require 'pry'
require 'json'
require 'rest-client'

@courses = []
Dir.glob('./1031/*.html') do |file_1031|
	string = File.read(file_1031)
	doc = Nokogiri::HTML(string.to_s)

	row_header_text = "選課類別\n課程類別\n開課系號\n開課序號\n課程名稱\n永久課號\n開課單位\n上課學制\n上課學院\n上課系所\n上課組別\n適用年級\n上課班別\n課程修別\n學分數\n時數\n學期數\n授課類別\n備註\n授課教師\n上課星期\n上課節次\n上課教室\n校區\n限修人數\n選上人數\n限選條件\n"

	tables = doc.css('table').select {|d| d.css('tr')[0].text == row_header_text && d.css('tr')[1].text != "\n查無任何開課資料!!\n" }
	if not tables.empty?
		tables[0].css('tr:not(:first-child)').each do |row|
      datas = row.css('td')
      @courses << {
        required: datas[1] && datas[1].text.strip,
        department_code: datas[2] && datas[2].text.strip,
        serial: datas[3] && datas[3].text.strip,
        name: datas[4] && datas[4].text.strip,
        code: datas[5] && datas[5].text.strip,
        department: datas[6] && datas[6].text.strip,
        school: datas[7] && datas[7].text.strip,
        field: datas[8] && datas[8].text.strip,
        grade: datas[11] && datas[11].text.strip,
        class_id: datas[12] && datas[12].text.strip,
        required_id: datas[13] && datas[13].text.strip,
        credit: datas[14] && datas[14].text.strip,
        hour: datas[15] && datas[15].text.strip,
        semester: datas[16] && datas[16].text.strip,
        class_classification: datas[17] && datas[17].text.strip,
        note: datas[18] && datas[18].text.strip,
        lecturer: datas[19] && datas[19].text.strip,
        day: datas[20] && datas[20].text.strip,
        class_time: datas[21] && datas[21].text.strip,
        classroom: datas[22] && datas[22].text.strip,
        location: datas[23] && datas[23].text.strip,
        student_counts: datas[24] && datas[24].text.strip,
      }
    end
	end
end

File.open('courses.json','w'){|file| file.write(JSON.pretty_generate(@courses))}