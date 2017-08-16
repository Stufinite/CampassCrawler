import requests
from bs4 import BeautifulSoup
import re
from pprint import pprint
import json
from UCrawler.items import UcrawlerItem
import pandas as pd
import scrapy
from scrapy.http import Request, FormRequest
import math


class NccuSpider(scrapy.Spider):
	name = 'NCCU'
	start_urls = ['https://wa.nccu.edu.tw/qrytor/Default.aspx?language=zh-TW']
	post_urls = ['https://wa.nccu.edu.tw/qrytor/qryScheduleResult.aspx?language=zh-TW']
	headers = {'user-agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36','referer':'http://www.ntpu.edu.tw/chinese/'}
	day_table = {
	    '一':1,
	    '二':2,
	    '三':3,
	    '四':4,
	    '五':5,
	    '六':6,
	    '日':7,

	    }

	time_table = {
	    'B':0,
	    '1':1,
	    '2':2,
	    '3':3,
	    '4':4,
	    '5':5,
	    '6':6,
	    '7':7,
	    '8':8,
	    'E':9,
	    'F':10,
	    'G':11,
	    'H':12,
	}

	def start_requests(self):
		res = requests.get(self.start_urls[0])
		soup = BeautifulSoup(res.text, 'lxml')

		sel = soup.select("#yyssDDL")[0]
		latest_semester = sel.find_all('option')[1]['value']

		sel = soup.select("#t_colLB")[0]
		opts = sel.find_all('option')[1:] #開課系級

		# Post 開課系級
		for opt in opts:
			dep = opt.text.replace(" ", "")
			print(dep)

			res = requests.get(self.start_urls[0])
			soup = BeautifulSoup(res.text, 'lxml')

			viewstate = soup.select("#__VIEWSTATE")[0]['value']
			viewstategenerator = soup.select("#__VIEWSTATEGENERATOR")[0]['value']
			eventvalidation = soup.select("#__EVENTVALIDATION")[0]['value']

			data = {
				'__EVENTTARGET':'searchA',
				'__VIEWSTATE':viewstate,
				'__VIEWSTATEGENERATOR':viewstategenerator,
				'__SCROLLPOSITIONX':'0',
				'__SCROLLPOSITIONY':'100',
				'__EVENTVALIDATION':eventvalidation,
				'yyssDDL':latest_semester,
				'languageCBL$0':'on',
				'languageCBL$1':'on',
				'languageCBL$2':'on',
				't_colLB':opt['value'],
				'lang':'1'
				}

			yield scrapy.FormRequest(self.start_urls[0], formdata=data, headers=self.headers)

			
	def parse(self, response):
		soup = BeautifulSoup(response.body, 'lxml')
		set_cookie = response.headers.get(b"Set-Cookie")
		cookie = str(set_cookie).split(";")[0].split("SessionId=")[1]
		cookies = {'ASP.NET_SessionId':cookie}

		while True:
			## Define column header
			df = pd.read_html(str(soup))[4]
			columns = ['dropOne']
			columns.extend(list(df.xs(0)[2:]))
			df.drop(df.columns[-1], axis=1, inplace=True) # drop the last column
			df.columns = columns
			df.drop(0, inplace=True)  


			## 處理單雙行
			courses = []
			for row in df.iterrows():
				row = row[1]
				if pd.notnull(row[1]) and re.match(r"[\d]{3}/[\d]{1}",row[1]):
					currentrow = dict(row)
				if  "異動資訊" in str(row[1]) and "備註" in str(row[1]):
					currentrow['note'] = str(row[1])
					currentrow['title'] = str(row[0])
					courses.append(currentrow)

			## 複製一課多班的課程
			singleCourses = []
			for course in courses:
				unprocessedDep = course['系所年級/開課院系']
				accDeps = []
				if len(unprocessedDep) <= 5:
					accDeps= [unprocessedDep]
				elif unprocessedDep in ['教務處通識教育中心',"教學發展中心"]:
					accDeps= [unprocessedDep]
				else:
					accDeps.extend(re.findall(r'[\u4e00-\u9fa5]{2}[一二三四]{1}[甲乙丙丁]{1}', unprocessedDep))
					accDeps.extend(re.findall(r'地[一二三四]{1}土[\u4e00-\u9fa5]{1}', unprocessedDep))
					for dep in accDeps:
						unprocessedDep = unprocessedDep.replace(dep, "")

					accDeps.extend(re.findall(r'[\u4e00-\u9fa5]{2,3}[一二三四]{1}', unprocessedDep))
					accDeps.extend(re.findall(r'科智碩[\d]{1}[AB]{1}', unprocessedDep))
					accDeps.extend(re.findall(r'經濟[博碩]{1}選', unprocessedDep))
					accDeps.extend(re.findall(r'東亞[博碩]{1}選', unprocessedDep))
					accDeps.extend(re.findall(r'教院[博碩]{1}士', unprocessedDep))
				if len(accDeps)==1:
					singleCourses.append(course)
				else:
					for dep in accDeps: 
						appendingCourse = course
						appendingCourse['系所年級/開課院系'] = dep
						singleCourses.append(appendingCourse)

            ## courseItem
			df_course = pd.DataFrame(singleCourses)

			for row in df_course.iterrows():
				courseItem = UcrawlerItem()
				courseItem['department'] = row['系所年級/開課院系'] if row['系所年級/開課院系'] != None else None
				courseItem['for_dept'] =  row['系所年級/開課院系'] if row['系所年級/開課院系'] != None else None
				courseItem['obligatory_tf'] = True if row['修別'] == '必/Required' else False
				courseItem['grade'] = row['系所年級/開課院系'] if row['系所年級/開課院系'] != None else None
				courseItem['title'] = row['title'] if row['title'] != None else None
				courseItem['note'] =  row['note'] if row['note'] != None else None
				courseItem['professor'] = row['任課教師暨學術專長'].replace(" ", "").split("/")[0].split("、") if row['任課教師暨學術專長'] != None else None

				courseItem['time'] = self.parse_time(row['上課時間'])
				courseItem['location'] = self.parse_location(row['教室'])

				courseItem['credits'] = float(row['學分']) if row['學分'] != None else None
				courseItem['code'] = row['科目代號'] if row['科目代號'] != None else None
				courseItem['campus'] = 'NCCU'
				courseItem['category'] = self.parse_category(row['系所年級/開課院系'], row['通識類別'], courseItem['title'], courseItem['obligatory_tf'])
				yield courseItem


			if 'href' not in str(soup.select("#nextLB")[0]):
				break

			# post Next Page
			viewstate = soup.select("#__VIEWSTATE")[0]['value']
			viewstategenerator = soup.select("#__VIEWSTATEGENERATOR")[0]['value']

			data = {
				'__EVENTTARGET':"nextLB",
				'__VIEWSTATE':viewstate,
				'__VIEWSTATEGENERATOR':viewstategenerator,
				'__SCROLLPOSITIONX':'0',
				'__SCROLLPOSITIONY':'200',
				'numberpageRBL':'50',
				'numberpageRBL2':'50'
				}
			
			res = requests.post(self.post_urls[0], data=data, headers=self.headers, cookies=cookies)
			soup = BeautifulSoup(res.text, 'lxml')

			pageMsg = soup.select("#FilterXX")[0].find("span").text
			pageNum = int(re.findall(r'[\d]+', pageMsg)[0])
			print(pageNum)

	@staticmethod
	def parse_location(location):
		classrooms = []
		if location!= None:
			if len(str(location)) <= 8:
				classrooms = [location]
			else:
				classrooms = re.findall(r'[\u4e00-\u9fa5]{2}[\d]{6}', location)
		return classrooms

	@classmethod
	def parse_time(self, ctime):
		ctime = re.sub(r'[ACD]{1}','',ctime)
		ctime = ctime.split("/")[0].replace(" ",'')
		timeLi = []

		if ctime == '未定或彈性':
			timeLi = None
		else:
			times = re.findall(r'[一二三四五六日]{1}[\dA-Z]+', ctime)
			for dtime in times:
				timeObj = {}
				timeObj['day'] = self.day_table.get(re.findall(r'[一二三四五六日]{1}', dtime)[0])
				timeObj['time'] = []
				for singleTime in list(re.sub(r'[一二三四五六日]{1}',"", dtime)):
					timeObj['time'].append(self.time_table.get(singleTime))
				timeLi.append(timeObj)

			timeLi = None if timeLi == [] else timeLi
		return timeLi

	@staticmethod
	def parse_category(dep, genEdu, title, obligatory_tf):
		depExist = dep!=None
		genEduExist = genEdu!=None
		if depExist and dep == "體育" :
			return "體育類"
		elif genEduExist: 
			return "通識類"
		elif "服務學習" in title or "全民國防" in title :
			return "其他類"
		else:
			return "必修類" if obligatory_tf else "選修類"


