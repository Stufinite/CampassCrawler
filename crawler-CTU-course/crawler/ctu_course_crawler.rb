require 'crawler_rocks'
require 'pry'
require 'iconv'
require 'json'

class CtuCourseCrawler

	GRADE = [
		'00',
		'01',
		'02',
		'03',
		'04',
	]

	CLASS = [
		'1',
		'2',
		'3',
		'4',
		'5',
		'6',
	]

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
  
    @update_progress_proc = update_progress
    @after_each_proc = after_each

  	end

  	def courses
  		@courses = []
  		url_r = []
  		# r1日間部 , r2進修部  , r3進修學院 
  		r1 = `curl -s "http://db.ctu.edu.tw/db_subject/index.aspx" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Referer: http://db.ctu.edu.tw/db_subject/index.aspx" -H "Origin: http://db.ctu.edu.tw" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.85 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" --data "__EVENTTARGET=ddl_Term&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE="%"2FwEPDwUKMTMyMzUxMTQ3Ng9kFgICAQ9kFgYCCQ8QZBAVAwnml6XplpPpg6gJ6YCy5L"%"2Bu6YOoDOmAsuS"%"2FruWtuOmZohUDCeaXpemWk"%"2BmDqAnpgLLkv67pg6gM6YCy5L"%"2Bu5a246ZmiFCsDA2dnZxYBAgFkAgsPEGQQFQgG5LqM5bCIBuS6jOaKgAblm5vmioAS5LqM5oqA5Zyo6IG35bCI54"%"2BtEuS6jOWwiOWcqOiBt"%"2BWwiOePrRLkuozlsIjmlJzmiYvlsIjnj60S5Zub5oqA5pSc5omL5bCI54"%"2BtEuS6jOaKgOaUnOaJi"%"2BWwiOePrRUIATMBNgE4AUEBRQFEAUkBRxQrAwhnZ2dnZ2dnZ2RkAg0PEA8WBh4NRGF0YVRleHRGaWVsZAUJY2xhX25hbWUyHg5EYXRhVmFsdWVGaWVsZAUGY2xhX25vHgtfIURhdGFCb3VuZGdkEBUZEumAmuitmOaVmeiCsuS4reW"%"2Fgw"%"2FmqZ"%"2FmorDlt6XnqIvns7sP6Zu75qmf5bel56iL57O7D"%"2Bmbu"%"2BWtkOW3peeoi"%"2Bezuw"%"2FlnJ"%"2FmnKjlt6XnqIvns7sY5bel5qWt6IiH5pyN5YuZ566h55CG57O7D"%"2Bizh"%"2BioiueuoeeQhuezuw"%"2Fmh4nnlKjlpJboqp7ns7sV5ZyL6Zqb5LyB5qWt566h55CG57O7EuiHquWLleWMluW3peeoi"%"2Bezuxjos4foqIroiIfntrLot6"%"2FpgJroqIrns7sY5qmf6Zu75YWJ57O757Wx56CU56m25omAD"%"2BWVhualreioreioiOezuw"%"2FnqbrplpPoqK3oqIjns7sY6YGL5YuV5YGl5bq36IiH5LyR6ZaS57O7Cee"%"2BjuWuueezuw"%"2FkvIHmpa3nrqHnkIbnp5EV6KO96YCg56eR5oqA56CU56m25omAFeaVuOS9jeWqkumrlOioreioiOezuwnop4DlhYnns7sY6KGM6Yq36IiH5pyN5YuZ566h55CG57O7GOmBiuaIsuiIh"%"2BeUouWTgeioreioiOezuyHlibXmhI"%"2FnlJ"%"2FmtLvmh4nnlKjoqK3oqIjnoJTnqbbmiYAe5pyN5YuZ6IiH56eR5oqA566h55CG56CU56m25omAABUZAjAwAjAxAjAyAjAzAjA0AjA1AjA2AjA3AjA4AjA5AjEwAjExAjEyAjEzAjE0AjE1AjE2AjE3AjE4AjE5AjIwAjIxAjIyAjIzABQrAxlnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZGQYAQUeX19Db250cm9sc1JlcXVpcmVQb3N0QmFja0tleV9fFgkFA3JiMQUDcmIyBQNyYjIFA3JiMwUDcmIzBQNyYjQFA3JiNAUDcmI1BQNyYjWzTRQpbQXXrOBCTNm3WTX4h4ReSg"%"3D"%"3D&__EVENTVALIDATION="%"2FwEWSwKc3uXzCAKrufu5DwKruf"%"2B5DwKrufO5DwKrufe5DwKrucu5DwKruc"%"2B5DwKrucO5DwKsua"%"2B6DwKsuaO6DwKsuee5DwKsufu5DwKsuf"%"2B5DwL22fjIDAL32fjIDALc98m"%"2BCQKM1r3hCQLhjPz1CALM066EBwKcp9CcAwL72cCJAQL82cCJAQLu2cCJAQKp2cCJAQKt2cCJAQKq2cCJAQKR2cCJAQKv2cCJAQLqoMSGBgLqoMiGBgLqoMyGBgLqoPCGBgLqoPSGBgLqoPiGBgLqoPyGBgLqoOCGBgLqoKSFBgLqoKiFBgL1oMSGBgL1oMiGBgL1oMyGBgL1oPCGBgL1oPSGBgL1oPiGBgL1oPyGBgL1oOCGBgL1oKSFBgL1oKiFBgL0oMSGBgL0oMiGBgL0oMyGBgL0oPCGBgL6z67rCgKAyrr8CgKPyrr8CgKOyrr8CgKNyrr8CgKMyrr8CgKLyrr8CgL7rKXjBgL6rKXjBgL5rKXjBgL4rKXjBgL"%"2FrKXjBgL"%"2BrKXjBgLB7quIAwLs0fbZDALmhbSVBQLs0bLrBgKLvJb"%"2BCALs0Yq1BQKw0"%"2FDLAgLs0e58AuzRgtgJAoznisYGUoOWD"%"2Fi"%"2FbGWPitMURQhAcsPSI9g"%"3D&ddlYear=04&ddlTerm=1&A=rb1&ddl_Term="%"E6"%"97"%"A5"%"E9"%"96"%"93"%"E9"%"83"%"A8&ddl_com=8&Ddl=01&ddl_Year=1&ddl_class=1&TextBox2=&TextBox1=&TextBox3=&TextBox4=&TextBox5=" --compressed`
  		r2 = `curl -s "http://db.ctu.edu.tw/db_subject/index.aspx" -H "Cookie: ASP.NET_SessionId=4qyb0n45rjtq3uvhfq0kd2al; __utmt=1; __utma=200776433.1720627521.1441865924.1441865924.1441872944.2; __utmb=200776433.1.10.1441872944; __utmc=200776433; __utmz=200776433.1441865924.1.1.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not"%"20provided)" -H "Origin: http://db.ctu.edu.tw" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-TW,zh;q=0.8,en-US;q=0.6,en;q=0.4" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.85 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: http://db.ctu.edu.tw/db_subject/index.aspx" -H "Connection: keep-alive" --data "__EVENTTARGET=ddl_Term&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE="%"2FwEPDwUKMTMyMzUxMTQ3Ng9kFgICAQ9kFgYCCQ8QZBAVAwnml6XplpPpg6gJ6YCy5L"%"2Bu6YOoDOmAsuS"%"2FruWtuOmZohUDCeaXpemWk"%"2BmDqAnpgLLkv67pg6gM6YCy5L"%"2Bu5a246ZmiFCsDA2dnZxYBZmQCCw8QZBAVCQnlm5vmioAoNCkM56CU56m25omAKDApCeS6jOaKgCgxKQ"%"2Fpq5TogrLlnIjpgbgoMikP6ZuZ6LuM5LqM5bCIKEIpD"%"2Bmbmei7jOS6jOaKgChIKQ"%"2Fpm5nou4zlm5vmioAoSykV55Si56CU56Kp5aOr5bCI54"%"2BtKE0pDOa1t"%"2BmdkuePrShNKRUJATQBMAExATIBQgFIAUsBTQFXFCsDCWdnZ2dnZ2dnZ2RkAg0PEA8WBh4NRGF0YVRleHRGaWVsZAUJY2xhX25hbWUyHg5EYXRhVmFsdWVGaWVsZAUGY2xhX25vHgtfIURhdGFCb3VuZGdkEBUZEumAmuitmOaVmeiCsuS4reW"%"2Fgw"%"2FmqZ"%"2FmorDlt6XnqIvns7sP6Zu75qmf5bel56iL57O7D"%"2Bmbu"%"2BWtkOW3peeoi"%"2Bezuw"%"2FlnJ"%"2FmnKjlt6XnqIvns7sY5bel5qWt6IiH5pyN5YuZ566h55CG57O7D"%"2Bizh"%"2BioiueuoeeQhuezuw"%"2Fmh4nnlKjlpJboqp7ns7sV5ZyL6Zqb5LyB5qWt566h55CG57O7EuiHquWLleWMluW3peeoi"%"2Bezuxjos4foqIroiIfntrLot6"%"2FpgJroqIrns7sY5qmf6Zu75YWJ57O757Wx56CU56m25omAD"%"2BWVhualreioreioiOezuw"%"2FnqbrplpPoqK3oqIjns7sY6YGL5YuV5YGl5bq36IiH5LyR6ZaS57O7Cee"%"2BjuWuueezuw"%"2FkvIHmpa3nrqHnkIbnp5EV6KO96YCg56eR5oqA56CU56m25omAFeaVuOS9jeWqkumrlOioreioiOezuwnop4DlhYnns7sY6KGM6Yq36IiH5pyN5YuZ566h55CG57O7GOmBiuaIsuiIh"%"2BeUouWTgeioreioiOezuyHlibXmhI"%"2FnlJ"%"2FmtLvmh4nnlKjoqK3oqIjnoJTnqbbmiYAe5pyN5YuZ6IiH56eR5oqA566h55CG56CU56m25omAABUZAjAwAjAxAjAyAjAzAjA0AjA1AjA2AjA3AjA4AjA5AjEwAjExAjEyAjEzAjE0AjE1AjE2AjE3AjE4AjE5AjIwAjIxAjIyAjIzABQrAxlnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZGQYAQUeX19Db250cm9sc1JlcXVpcmVQb3N0QmFja0tleV9fFgkFA3JiMQUDcmIyBQNyYjIFA3JiMwUDcmIzBQNyYjQFA3JiNAUDcmI1BQNyYjXJDtJWVJt"%"2FEzfdaH3N"%"2FaxvuZ4WNg"%"3D"%"3D&__EVENTVALIDATION="%"2FwEWTAKd5q6"%"2FDwKrufu5DwKruf"%"2B5DwKrufO5DwKrufe5DwKrucu5DwKruc"%"2B5DwKrucO5DwKsua"%"2B6DwKsuaO6DwKsuee5DwKsufu5DwKsuf"%"2B5DwL22fjIDAL32fjIDALc98m"%"2BCQKM1r3hCQLhjPz1CALM066EBwKcp9CcAwL62cCJAQLm2cCJAQL52cCJAQL42cCJAQKo2cCJAQKe2cCJAQKT2cCJAQKV2cCJAQKf2cCJAQLqoMSGBgLqoMiGBgLqoMyGBgLqoPCGBgLqoPSGBgLqoPiGBgLqoPyGBgLqoOCGBgLqoKSFBgLqoKiFBgL1oMSGBgL1oMiGBgL1oMyGBgL1oPCGBgL1oPSGBgL1oPiGBgL1oPyGBgL1oOCGBgL1oKSFBgL1oKiFBgL0oMSGBgL0oMiGBgL0oMyGBgL0oPCGBgL6z67rCgKAyrr8CgKPyrr8CgKOyrr8CgKNyrr8CgKMyrr8CgKLyrr8CgL7rKXjBgL6rKXjBgL5rKXjBgL4rKXjBgL"%"2FrKXjBgL"%"2BrKXjBgLB7quIAwLs0fbZDALmhbSVBQLs0bLrBgKLvJb"%"2BCALs0Yq1BQKw0"%"2FDLAgLs0e58AuzRgtgJAoznisYGWH6Kr3oyc77Lv7Ladi6nYvo7xiA"%"3D&ddlYear=04&ddlTerm=1&A=rb1&ddl_Term="%"E9"%"80"%"B2"%"E4"%"BF"%"AE"%"E9"%"83"%"A8&ddl_com=4&Ddl=00&ddl_Year=1&ddl_class=1&TextBox2=&TextBox1=&TextBox3=&TextBox4=&TextBox5=" --compressed`
  		r3 = `curl -s "http://db.ctu.edu.tw/db_subject/index.aspx" -H "Cookie: ASP.NET_SessionId=4qyb0n45rjtq3uvhfq0kd2al; __utmt=1; __utma=200776433.1720627521.1441865924.1441865924.1441872944.2; __utmb=200776433.1.10.1441872944; __utmc=200776433; __utmz=200776433.1441865924.1.1.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not"%"20provided)" -H "Origin: http://db.ctu.edu.tw" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-TW,zh;q=0.8,en-US;q=0.6,en;q=0.4" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.85 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: http://db.ctu.edu.tw/db_subject/index.aspx" -H "Connection: keep-alive" --data "__EVENTTARGET=ddl_Term&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE="%"2FwEPDwUKMTMyMzUxMTQ3Ng9kFgICAQ9kFgYCCQ8QZBAVAwnml6XplpPpg6gJ6YCy5L"%"2Bu6YOoDOmAsuS"%"2FruWtuOmZohUDCeaXpemWk"%"2BmDqAnpgLLkv67pg6gM6YCy5L"%"2Bu5a246ZmiFCsDA2dnZxYBAgFkAgsPEGQQFQgG5LqM5bCIBuS6jOaKgAblm5vmioAS5LqM5oqA5Zyo6IG35bCI54"%"2BtEuS6jOWwiOWcqOiBt"%"2BWwiOePrRLkuozlsIjmlJzmiYvlsIjnj60S5Zub5oqA5pSc5omL5bCI54"%"2BtEuS6jOaKgOaUnOaJi"%"2BWwiOePrRUIATMBNgE4AUEBRQFEAUkBRxQrAwhnZ2dnZ2dnZ2RkAg0PEA8WBh4NRGF0YVRleHRGaWVsZAUJY2xhX25hbWUyHg5EYXRhVmFsdWVGaWVsZAUGY2xhX25vHgtfIURhdGFCb3VuZGdkEBUZEumAmuitmOaVmeiCsuS4reW"%"2Fgw"%"2FmqZ"%"2FmorDlt6XnqIvns7sP6Zu75qmf5bel56iL57O7D"%"2Bmbu"%"2BWtkOW3peeoi"%"2Bezuw"%"2FlnJ"%"2FmnKjlt6XnqIvns7sY5bel5qWt6IiH5pyN5YuZ566h55CG57O7D"%"2Bizh"%"2BioiueuoeeQhuezuw"%"2Fmh4nnlKjlpJboqp7ns7sV5ZyL6Zqb5LyB5qWt566h55CG57O7EuiHquWLleWMluW3peeoi"%"2Bezuxjos4foqIroiIfntrLot6"%"2FpgJroqIrns7sY5qmf6Zu75YWJ57O757Wx56CU56m25omAD"%"2BWVhualreioreioiOezuw"%"2FnqbrplpPoqK3oqIjns7sY6YGL5YuV5YGl5bq36IiH5LyR6ZaS57O7Cee"%"2BjuWuueezuw"%"2FkvIHmpa3nrqHnkIbnp5EV6KO96YCg56eR5oqA56CU56m25omAFeaVuOS9jeWqkumrlOioreioiOezuwnop4DlhYnns7sY6KGM6Yq36IiH5pyN5YuZ566h55CG57O7GOmBiuaIsuiIh"%"2BeUouWTgeioreioiOezuyHlibXmhI"%"2FnlJ"%"2FmtLvmh4nnlKjoqK3oqIjnoJTnqbbmiYAe5pyN5YuZ6IiH56eR5oqA566h55CG56CU56m25omAABUZAjAwAjAxAjAyAjAzAjA0AjA1AjA2AjA3AjA4AjA5AjEwAjExAjEyAjEzAjE0AjE1AjE2AjE3AjE4AjE5AjIwAjIxAjIyAjIzABQrAxlnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZGQYAQUeX19Db250cm9sc1JlcXVpcmVQb3N0QmFja0tleV9fFgkFA3JiMQUDcmIyBQNyYjIFA3JiMwUDcmIzBQNyYjQFA3JiNAUDcmI1BQNyYjWzTRQpbQXXrOBCTNm3WTX4h4ReSg"%"3D"%"3D&__EVENTVALIDATION="%"2FwEWSwKc3uXzCAKrufu5DwKruf"%"2B5DwKrufO5DwKrufe5DwKrucu5DwKruc"%"2B5DwKrucO5DwKsua"%"2B6DwKsuaO6DwKsuee5DwKsufu5DwKsuf"%"2B5DwL22fjIDAL32fjIDALc98m"%"2BCQKM1r3hCQLhjPz1CALM066EBwKcp9CcAwL72cCJAQL82cCJAQLu2cCJAQKp2cCJAQKt2cCJAQKq2cCJAQKR2cCJAQKv2cCJAQLqoMSGBgLqoMiGBgLqoMyGBgLqoPCGBgLqoPSGBgLqoPiGBgLqoPyGBgLqoOCGBgLqoKSFBgLqoKiFBgL1oMSGBgL1oMiGBgL1oMyGBgL1oPCGBgL1oPSGBgL1oPiGBgL1oPyGBgL1oOCGBgL1oKSFBgL1oKiFBgL0oMSGBgL0oMiGBgL0oMyGBgL0oPCGBgL6z67rCgKAyrr8CgKPyrr8CgKOyrr8CgKNyrr8CgKMyrr8CgKLyrr8CgL7rKXjBgL6rKXjBgL5rKXjBgL4rKXjBgL"%"2FrKXjBgL"%"2BrKXjBgLB7quIAwLs0fbZDALmhbSVBQLs0bLrBgKLvJb"%"2BCALs0Yq1BQKw0"%"2FDLAgLs0e58AuzRgtgJAoznisYGUoOWD"%"2Fi"%"2FbGWPitMURQhAcsPSI9g"%"3D&ddlYear=04&ddlTerm=1&A=rb1&ddl_Term="%"E9"%"80"%"B2"%"E4"%"BF"%"AE"%"E5"%"AD"%"B8"%"E9"%"99"%"A2&ddl_com=3&Ddl=00&ddl_Year=1&ddl_class=1&TextBox2=&TextBox1=&TextBox3=&TextBox4=&TextBox5=" --compressed`
        
  		url_r << r1 
  		url_r << r2
  		url_r << r3

  		url_r.each do |rl|

	  		doc = Nokogiri::HTML(rl)
	  		# get information form post_url for get_url
	  		dep_code = doc.css('select[name="Ddl"]').css('option').map{|u| u['value']}
	  		term_class = doc.css('select[name="ddl_com"]').css('option').map{|u| u['value']}
			dep_code.each do |dep|
				term_class.each do |_term|
					GRADE.each do |grade|
						CLASS.each do |_classL|
							puts dep_code.size.to_s + "/" + (dep_code.index(dep)+1).to_s + "," + term_class.size.to_s + "/" + (term_class.index(_term)+1).to_s + "," + GRADE.size.to_s + "/" + (GRADE.index(grade)+1).to_s + "," + CLASS.size.to_s + "/" + (CLASS.index(_classL)+1).to_s

					  		@get_url = "http://db.ctu.edu.tw/db_subject/qry_sub.aspx?cla_num=#{grade}#{_term}#{dep}#{_classL}&qType=1&qYear=#{(@year-1911).to_s[1..2]}#{@term}"
					  		r = RestClient.get @get_url
					  		doc = Nokogiri::HTML(r)
					  		index = doc.css('table').css('tr')
					  		index[3..-2].each do |row|
					  			datas = row.css('td')

					  			course_days = [] 
								course_periods = []
								course_locations = []

					  			day_course = datas[7].text.split /(..)/
					  			day_course.each do |_course|
					  				if(_course.size!=0)
					  					course_days << _course[0]
					  					course_periods << _course[1]
					  					course_locations << datas[8].text.strip
					  				end
					  			end
					  		


								course = {
									name: datas[2].css('a')[0].text.strip,
									year: @year,
									term: @term,
									code: "#{@year}-#{@term}-"+ datas[0].text.strip,
									degree: datas[1].text.strip,
									credits: datas[3].text.strip,
									lecturer: datas[6].text.strip,
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
			end
	  	end
	  	@courses
  	end

end

cwl = CtuCourseCrawler.new(year: 2015, term: 1)
File.write('courses.json', JSON.pretty_generate(cwl.courses))