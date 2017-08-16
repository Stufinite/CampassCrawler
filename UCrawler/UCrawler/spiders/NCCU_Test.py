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
	name = 'NCCU_Test'
	start_urls = ['https://wa.nccu.edu.tw/qrytor/Default.aspx?language=zh-TW']
	post_urls = ['https://wa.nccu.edu.tw/qrytor/qryScheduleResult.aspx?language=zh-TW']
	headers = {'user-agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36','referer':'https://wa.nccu.edu.tw'}
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
	cookies = None

	def start_requests(self):
		res = requests.get(self.start_urls[0])
		self.cookies = {'ASP.NET_SessionId':res.cookies['ASP.NET_SessionId']}
		soup = BeautifulSoup(res.text, 'lxml')

		sel = soup.select("#yyssDDL")[0]
		latest_semester = sel.find_all('option')[1]['value']

		sel = soup.select("#t_colLB")[0]
		opts1 = sel.find_all('option')[1:] #開課系級

		NotFirst0 = False
		NotFirst1 = False
		NotFirst2 = False

		# Post 開課系級
		for opt1 in opts1[0:1]:
			if NotFirst0:
				soup = self.getFirstPage()
			NotFirst0 = True

			soup = self.postSecondPage(soup, latest_semester, opt1)
			sel = soup.select("#gde_tpeLB")[0]
			opts2 = sel.find_all('option')[1:]  #大學、研究所

		    #Post 大學、研究所
			for opt2 in opts2:

				if NotFirst1:
					soup = self.getFirstPage()
					soup = self.postSecondPage(soup, latest_semester, opt1)
				NotFirst1 = True
		        
				soup = self.postThirdPage(soup, latest_semester, opt1, opt2)
				sel = soup.select("#t_depLB")[0]
				opts3 = sel.find_all('option')[1:]  #系所

				#Post 系所
				for opt3 in opts3:
					dep = opt3.text.replace(" ", "")
					cat = opt2.text.replace(" ", "")

					if NotFirst2:
						soup = self.getFirstPage()
						soup = self.postSecondPage(soup, latest_semester, opt1)
						soup = self.postThirdPage(soup, latest_semester, opt1, opt2)
					NotFirst2 = True
		            
					data = self.getPostData('searchA', soup, latest_semester, opt1['value'], opt2['value'], opt3['value'])
					# yield scrapy.FormRequest(self.start_urls[0], formdata=data, headers=self.headers, meta={'dep':dep, 'cat':cat})
					if cat == '整開/IntegratedCourses' and dep== '總體經濟學/Macroeconomics':
						yield scrapy.FormRequest(self.start_urls[0], formdata=data, headers=self.headers, meta={'dep':dep, 'cat':cat})

			
	def parse(self, response):
		print(response.meta['cat'])
		print(response.meta['dep'])
		soup = BeautifulSoup(response.body, 'lxml')

		while True:
			## Define column header
			df = pd.read_html(str(soup))[4]

			## if courses Length < 10 ,the side column will disappear(外語學院>碩士班>日本語文學系) 
			courseLen = len(df[pd.notnull(df[0])])-1  ##minus column header
			if courseLen >= 10:
				columns = ['加入我的追蹤清單']
				columns.extend(list(df.xs(0)[2:]))
				df.drop(df.columns[-1], axis=1, inplace=True) # drop the last column
				df.columns = columns
				df.drop(0, inplace=True)  
			else:
				columns = list(df.xs(0))
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


			df_course = pd.DataFrame(singleCourses)
			df_course.to_csv("NCCU5.csv")


			for row in df_course.iterrows():
				def preprocess(item):
					if pd.isnull(item):
						return None
					else:
						return str(item)
				row = pd.Series(row[1]).apply(preprocess)
		
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

			pageMsg = soup.select("#FilterXX")[0].find("span").text
			pageNum = int(re.findall(r'[\d]+', pageMsg)[0])
			print(pageNum)
			print(len(df_course))
			break


			# if 'href' not in str(soup.select("#nextLB")[0]):
			# 	break

			# # post Next Page
			# viewstate = soup.select("#__VIEWSTATE")[0]['value']
			# viewstategenerator = soup.select("#__VIEWSTATEGENERATOR")[0]['value']

			# data = {
			# 	'__EVENTTARGET':"nextLB",
			# 	'__VIEWSTATE':viewstate,
			# 	'__VIEWSTATEGENERATOR':viewstategenerator,
			# 	'__SCROLLPOSITIONX':'0',
			# 	'__SCROLLPOSITIONY':'200',
			# 	'numberpageRBL':'50',
			# 	'numberpageRBL2':'50'
			# 	}
			
			# res = requests.post(self.post_urls[0], data=data, headers=self.headers, cookies=self.cookies)
			# soup = BeautifulSoup(res.text, 'lxml')

			# pageMsg = soup.select("#FilterXX")[0].find("span").text
			# pageNum = int(re.findall(r'[\d]+', pageMsg)[0])
			# print(pageNum)

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


		# Get First Page
	@classmethod
	def getFirstPage(cls):
		res = requests.get(cls.start_urls[0], cookies=cls.cookies)
		soup = BeautifulSoup(res.text, 'lxml')
		return soup
	    
	@classmethod
	def postSecondPage(cls, soup, latest_semester, opt1):
		data = cls.getPostData('t_colLB', soup, latest_semester, opt1['value'])
		res = requests.post(cls.start_urls[0], data=data, headers=cls.headers, cookies=cls.cookies)
		soup = BeautifulSoup(res.text, 'lxml')
		return soup
	    
	@classmethod
	def postThirdPage(cls, soup, latest_semester, opt1, opt2):
		data = cls.getPostData('gde_tpeLB', soup, latest_semester, opt1['value'], opt2['value'])
		res = requests.post(cls.start_urls[0], data=data, headers=cls.headers, cookies=cls.cookies)
		soup = BeautifulSoup(res.text, 'lxml')
		return soup

	@staticmethod
	def getPostData(eventtarget, soup, latest_semester, t_colLB, gde_tpeLB=None, t_depLB=None):
		viewstate = soup.select("#__VIEWSTATE")[0]['value']
		viewstategenerator = soup.select("#__VIEWSTATEGENERATOR")[0]['value']
		eventvalidation = soup.select("#__EVENTVALIDATION")[0]['value']

		data = {
			'__EVENTTARGET':eventtarget,
			'__VIEWSTATE':viewstate,
			'__VIEWSTATEGENERATOR':viewstategenerator,
			'__SCROLLPOSITIONX':'0',
			'__SCROLLPOSITIONY':'100',
			'__EVENTVALIDATION':eventvalidation,
			'yyssDDL':latest_semester,
			'languageCBL$0':'on',
			'languageCBL$1':'on',
			'languageCBL$2':'on',
			't_colLB':t_colLB,
			'gde_tpeLB':gde_tpeLB,
			't_depLB':t_depLB,
			'lang':'1'
			}

		return data

