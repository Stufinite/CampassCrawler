require 'crawler_rocks'
require 'pry'
require 'iconv'
require 'json'

class CnuCouurseCrawler


	DEP = [
	'4E16','4E17','4E18','4E26','4E27','4E28','4E36','4E37','4E46','4E47',
	'4F16','4F26','XY63','XY67','XY73','XY74','XY77','4111','4112','4113',
	'4114','4121','4122','4123','4124','4131','4133','4134','4141','4142',
	'4143','4144','4151','4161','4211','4212','4221','4222','4231','4232',
	'4241','4242','4252','4261','4311','4312','4321','4322','4331','4332',
	'4341','4342','4351','4361','4411','4412','4413','4414','4421','4422',
	'4423','4431','4432','4433','4441','4442','4443','4451','4461','4471',
	'4511','4512','4513','4521','4522','4523','4531','4532','4533','4541',
	'4542','4543','4551','4561','4611','4612','4621','4622','4632','4641',
	'4642','4651','4661','4711','4712','4713','4714','4721','4722','4723',
	'4724','4731','4732','4733','4734','4741','4742','4743','4744','4751',
	'4761','4811','4812','4813','4821','4822','4823','4824','4831','4832',
	'4833','4834','4841','4842','4843','4844','4851','4861','4911','4912',
	'4913','4921','4922','4923','4932','4933','4932','4933','4941','4942',
	'4943','4951','4961','4A11','4A12','4A13','4A21','4A22','4A23','4A31',
	'4A32','4A33','4A41','4A42','4A43','4A51','4A61','4B11','4B12','4B13',
	'4B14','4B21','4B22','4B23','4B24','4B31','4B32','4B33','4B34','4B41',
	'4B42','4B43','4B44','4B51','4B61','4C11','4C12','4C13','4C21','4C22',
	'4C23','4C31','4C32','4C33','4C41','4C42','4C43','4C51','4C61','4D11',
	'4D12','4D21','4D22','4D31','4D32','4D41','4D42','4D51','4D61','4E11',
	'4E12','4E13','4E21','4E22','4E23','4E31','4E32','4E33','4E41','4E41',
	'4E42','4E43','4E51','4E61','4F11','4F12','4F21','4F22','4F23','4F31',
	'4F32','4F33','4F41','4F42','4F43','4F51','4F61','4G11','4G12','4G21',
	'4G22','4G31','4G32','4G41','4G42','4G51','4G61','4I11','4I12','4I21',
	'4I22','4I31','4I32','4I41','4I42','4I51','4I61','4K21','4K22','4K31',
	'4K32','4K41','4K42','4K51','4K61','4L11','4L12','4L21','4L22','4L31',
	'4L32','4L41','4L42','4L51','4L61','4N11','4N12','4N21','4N31','4N32',
	'4N41','4N42','4N51','4N52','4S11','4S12','4S21','4S22','4S31','4S32',
	'4S41','4S42','4S51','4S61','4T11','4T12','4T13','4T21','4T22','4T23',
	'4T31','4T32','4T33','4T41','4T42','4T43','4T51','4T61','4U11','4U12',
	'4U21','4U22','4U31','4U32','4U41','4U42','4U51','4U61','4V21','4V31',
	'4V41','XY01','XY02','XY03','XY04','XY05','XY06','XY07','XY09','XY10',
	'XY11','XY13','XY14','XY15','XY16','XY17','XY1N','XY1U','XY20','XY21',
	'XY23','XY24','XY27','XY28','XY2C','XY2N','XY2U','XY30','XY33','XY38',
	'XY3C','XY3N','XY99','XYZ0','XYZ1','6631','6711','6712','6721','6722',
	'6731','6811','6831','6841','6E11','6E21','6E31','6E41','4F21','6F22',
	'6F31','6F41','6S11','6S21','6S31','9M12','9M22','9M32','9611','9621',
	'9631','9641','9F11','9F21','9F31','9F41','9H11','9H21','9H31','9I11',
	'9I21','9J11','9J21','9J31','9J41','9M11','9M21','9O11','9O21','9O31',
	'9O41','9P11','9P21','9P31','9P41','9Q11','9Q21','9Q31','9Q41','9R11',
	'9R21','9R41','9T11','9T21','9W11','9W21','9W31','XY85','XY89','XY8C',
	'XY9C','8318','8328','8338','8348','8448','8538','8548','8638','8748',
	'8918','8928','8938','8948','8A38','8A48','8B18','8B28','8B38','8B48',
	'8C18','8C28','8C38','8C48','8E18','8E19','8E28','8E38','8E48','8F19',
	'8F48','8G38','8G48','8L38','8L48','8N18','8N28','8N38','8N48','8T38',
	'8T48','8U38','8U48','8311','8321','8331','8341','8411','8421','8431',
	'8441','8511','8521','8531','8541','8611','8621','8631','8641','8711',
	'8712','8721','8722','8731','8741','8742','8911','8912','8931','8941',
	'8A11','8A21','8A31','8A41','8B11','8B12','8B21','8B22','8B31','8B41',
	'8B42','8C11','8C21','8C31','8C41','8D11','8D12','8D21','8D31','8D41',
	'8E11','8E12','8E21','8E22','8E23','8E31','8E32','8E33','8E41','8E42',
	'8F11','8F21','8F31','8F41','8G11','8G21','8G31','8G41','8G41','8L11',
	'8L12','8L21','8L22','8L31','8L32','8L41','8N11','8N12','8N21','8N22',
	'8N31','8N32','8N41','8N42','8T11','8T21','8T31','8T41','8U11','8U21',
	'8U31','8U41','XYZ6','XYZ7','7512','7522','7712','7722','7A12','7A22',
	'7E12','7E22','7S12','7S22','A611','A622','AA11','AA21','AF11','AF21',
	'AH11','AH21','AJ11','AJ21','AM11','AM21','AP11','AP21','AQ11','AQ21',
	'RE11','P311','P321','PA11','PA21','PE21','8715','8725','8735','8745',
	'7319',
	]

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil
		@year = year
   		@term = term
   	
    	@update_progress_proc = update_progress
    	@after_each_proc = after_each
    	@ic = Iconv.new('utf-8//IGNORE', 'big5')
	end

	def courses
    @courses = []

    DEP.each do |dep|
    	puts DEP.size.to_s + "/" + (DEP.index(dep)+1).to_s + " department code :" + dep
	    @url_get = "http://192.192.45.38/SC2008/STPJ/STPJ_S_SUB(TZU).ASP?CLNO=#{dep}"
	    r = RestClient.get @url_get
	    doc = Nokogiri::HTML(@ic.iconv(r))
	    have_sch = doc.css('table')[0].css('tr')[2].css('td')[1].text[0..-1] # if class exist ? , > 0 is yes

	    if(have_sch.size > 10)
	    	puts "in sch!!!"
		    index = doc.css('table')[0].css('tr')

		    index[2..-1].each do |row|
		    	if(row.css('td')[1].text[0..-1].size > 10)
			    	datas = row.css('td')

			    	course_days = []
					course_periods = []
					course_locations = []
					daytemp = nil

					period_temp = datas[8..14].text.split /(\d\d?-?\d?\d?)/
					
					if(period_temp[1]!=nil)
						period_start = period_temp[1][0].to_i
						period_end = period_temp[1][2..3].to_i
						period_end = period_start if (period_end==0)
						
						if(period_end==period_start)
						
							8.upto(14) do |days|
							daytemp = days - 7 if datas[days].text[1].to_i == period_start
							end
						else
							8.upto(14) do |days|
							daytemp = days - 7 if datas[days].text.size > 2
							end
						end

						period_start.upto(period_end) do |day_class|
							course_days << daytemp
							course_periods << day_class
							course_locations << datas[6].text
						end
					end

					course = {
							name: "#{datas[1].text[11..-1]}",
							year: @year,
							term: @term,
							code: "#{@year}-#{@term}-#{datas[1].css('font')[1].text.strip}",
							class_no: "#{datas[5].css('font')[0].text.strip}",
							credits: "#{datas[3].text.strip}",
							lecturer: "#{datas[5].css('font')[1].text.strip}",
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

cwl = CnuCouurseCrawler.new(year: 2015, term: 1)
File.write('courses.json', JSON.pretty_generate(cwl.courses))