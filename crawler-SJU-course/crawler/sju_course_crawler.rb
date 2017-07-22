require 'crawler_rocks'
require 'pry'
require 'iconv'
require 'json'

class SjuCouurseCrawler



	DEP = [
	'D11210','D11211','D11212','D11220','D11220','D11222','D11230','D11231','D11230','D11241',
	'D11242','D11510','D11511','D11512','D11520','D11521','D11522','D11530','D11531','D11532',
	'D11541','D11542','D12810','D12811','D12812','D12813','D12820','D12821','D12822','D12823',
	'D12831','D12832','D12833','D12842','D12843','D12410','D13411','D13412','D13420','D13421',
	'D13422','D13430','D13431','D13432','D13441','D13442','D13510','D13511','D13512','D13520',
	'D13521','D13522','D13531','D13532','D13541','D13542','D14010','D14011','D14012','D14020',
	'D14021','D14022','D14030','D14031','D14032','D14041','D14042','D14120','D14120','D14122',
	'D14130','D14131','D14132','D14141','D14142','D15210','D15211','D15212','D21010','D21011',
	'D21012','D21020','D21021','D21022','D21030','D21031','D21032','D21041','D21042','D21720',
	'D21721','D21730','D21731','D21741','D21810','D21811','D21820','D21821','D21822','D21830',
	'D21831','D21832','D21841','D21842','D22210','D22211','D22212','D22220','D22221','D22222',
	'D22230','D22231','D22232','D22241','D22242','D23610','D23611','D23612','D23620','D23621',
	'D23622','D23630','D23631','D23632','D23641','D23642','D23841','D23842','D23843','D24541',
	'D24542','D30410','D30411','D30412','D30413','D30420','D30421','D30422','D30430','D30431',
	'D30432','D30433','D30441','D30442','D30443','D30610','D30611','D30612','D30620','D30621',
	'D30622','D30631','D30632','D30641','D30642','D32110','D32111','D32112','D32120','D32121',
	'D32122','D32123','D32130','D32131','D32132','D32141','D32142','D33710','D33711','D33712',
	'D33720','D33721','D33731','D33741','D40710','D40711','D40720','D40721','D40731','D40741',
	'D41310','D41311','D41312','D41313','D41320','D41321','D41322','D41323','D41330','D41331',
	'D41332','D41341','D41342','D51710','D51711','D53831','D53832','D53833','D54510','D54511',
	'D54512','D54520','D54521','D54522','D54530','D54531','D54532','D54910','D54911','D54920',
	'D54921','D54931','D55110','D55111','D55112','D55113','D55120','D55121','D55122','D55123',
	'EA11','EA21','EB11','EB12','EB21','EB22','C11230','C11231','C11241','C11530',
	'C11531','C11541','C12841','C13430','C13431','C13441','C22230','C22231','C22241','C23841',
	'C30441','C53831','C53841','C55130','C55131','C55141','740510','740511','740512','740520',
	'740521','745022','740530','740531','740532','740541','740542','740551','740552','740560',
	'740561','740562','740571','740572','740711','740720','740721','740730','740731','740741',
	'740751','740761','740771','741310','741311','741312','741320','741321','741322','741330',
	'741331','741332','741341','741342','741351','741352','741361','741362','741371','741372',
	'510351','530651','531151','532951','A10121','A15011','A15021','A20211','A20911','A24711',
	'A24721','A34611','A34621','A44211','A44221','A44311','A44321','EA11','EA21','EB11',
	'EB12','EB21','EB22','Q611','Q621','Q631','Q641','Q841','Q941','QC11',
	'QC21','QC31','QC41','QD11','QD21','QD31','QD41','QE11','QE12','QE21',
	'QE31','QE32','QE41','QE42','QG11','QG21','QG31','QG41','QJ11','QJ21',
	'QJ31','QJ41','QK41','QJ42','QL11','QL21','QL31','QL41','QN11','QN12',
	'QN13','QN21','QN22','QN23','QN31','QN32','QN33','QN41','QN42','QN43',
	'QP11','QP21','QP31','QQ31','QQ41','QR11','QR21','QR31','QT11','QT21',
	'QT31','QT41','QU11','QU21','QU31','QU41','QV11','QV21','QV31','QV41',
	'QW11','QW21','QW31','QW41','QX11','QX21','QX31','QX41','QY31','QY41',
	'YE11','PE36','PE46','PF36','PF46','PJ36','PJ46','PN36','PN46','PX36',
	'PX46','B101-1','B101-2','B101-3','B101-4','B102-1','B102-2','B102-3','B102-4','B103-1',
	'B103-2','B103-3','B103-4','B103-5','B103-6','B104-1','B104-2','SE1010','SE102-1','SE102-2',
	'SE103-1','SE103-2','SE104','SE223','SE234','U1030','H97','H97-1','H97-2','H97-3',
	'H97-4','HK102-1','113','1A11','1B11','1B12','1B13','1C11','1C12','1C13',
	'1C14','1C15','1C16','1C17','1D11','1D12','1D21','1D22','1E11','1E21',
	'1E22','1E23','1E23','1E24','1E25','1E26','1E31','1F11','1F21','1F22',
	'1F31','1F32','1F33','1F41','1F51','1G11','1G12','1H11','1H12','1H13',
	'1H14','1H15','1H16','1H17','1H18','1H19','1I11','1I12','1J11','1L11',
	'1L12','1M11','1R11','1R12','1S12','1S13','1T11','1T12','1U10','1U11',
	'1U12','1U13','1U14','1V11','1V12','1V13','1Y11','1Z11','EA01','EA02',
	'EB01','EB02','EB03','EB04','P541','P551','PD31','PD41','PR31','PR41',
	'PS31','PS41','PS42','RC11','RC21','RC31','RC41','RV11','RV21','RV31',
	'RW12','RW22','SN31','SN41','M811','M821','MA11','MA21','MA31','MB11',
	'MB21','MB31','MK21','MP11','MP21','MT11','MT21','YM11','HE11','HW11',
	'HW21','HW31','HW41',
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
	    @url_get = "http://192.192.3.194/SC2008/STPJ/STPJ_S_SUB(TUT).ASP?CLNO=#{dep}"
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
							name: "#{datas[1].text.strip}",
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

cwl = SjuCouurseCrawler.new(year: 2015, term: 1)
File.write('courses.json', JSON.pretty_generate(cwl.courses))