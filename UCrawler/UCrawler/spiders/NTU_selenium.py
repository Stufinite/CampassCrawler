# -*- coding: utf-8 -*-
import scrapy
# from scrapy.http import Request, FormRequest, TextResponse
from bs4 import BeautifulSoup
from selenium import webdriver
import pandas as pd
import re
import math
from UCrawler.items import UcrawlerItem
from .setting_selenium import cross_selenium, tryLocateElemById, tryLocateElemByXpath, tryLocateElemBySelector
#from UCrawler.items import UcrawlerItem

class NtuSpider(scrapy.Spider):
	name = 'NTU_selenium'
	allowed_domains = ['aisap.nutc.edu.tw']
	# start_urls = ['https://nol.ntu.edu.tw/nol/coursesearch/search_for_02_dpt.php']
	start_urls = ['https://doc.scrapy.org/en/latest/topics/request-response.html']
	headers = {'user-agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36','referer':'http://www.ntpu.edu.tw/chinese/'}
	day_table = {
	    '一':1,
	    '二':2,
	    '三':3,
	    '四':4,
	    '五':5,
	    '六':6,
	}
	html = ""
	genEduCodeLi = []

	def parse(self, response):
		countPerPage = 2000

		## get other category coursecode list
		driver = cross_selenium()
		url = "https://nol.ntu.edu.tw/nol/coursesearch/search_for_01_major.php"
		driver.get(url)
		try:
			element = tryLocateElemById(driver, "couarea")
		finally:
			options = element.find_elements_by_tag_name("option")
			for i in range(0, len(options)):
				try:
					element = tryLocateElemById(driver, "couarea")
				finally:
					element.find_elements_by_tag_name("option")[i].click()
					self.sendPageCountAndSubmit(driver, countPerPage)
					driver.implicitly_wait(3)

					df_course = self.preprocessTable(driver.page_source, 7)
					self.genEduCodeLi.extend(list(set(df_course['課號'])))
		print("get other catgory course list")
		driver.close()

		## Start crawl page
		driver = cross_selenium()
		url = 'https://nol.ntu.edu.tw/nol/coursesearch/search_for_02_dpt.php'
		driver.get(url)
		self.sendPageCountAndSubmit(driver, countPerPage)
		driver.implicitly_wait(10)

		try:
			Xpath = '/html/body/table[2]/tbody/tr/td/font/table[2]/tbody/tr/td[1]/font/b'
			elem = tryLocateElemByXpath(driver, Xpath)
		finally:
			dataLength = elem.text
			pageNum = math.floor(int(dataLength)/countPerPage)+1

		for i in range(1,pageNum+1):
			# if i == 1:
			# 	print("第1頁")
			# 	self.html = driver.page_source
			# 	self.htmlparser(self.html)
			# 	# yield TextResponse(url=self.start_urls[0], body=driver.page_source, encoding='utf8')
			# else:
			try:
				Xpath = '/html/body/table[2]/tbody/tr/td/font/table[2]/tbody/tr/td[2]/select/option[{}]'.format(i)
				elem = tryLocateElemByXpath(driver, Xpath)
			finally:
				driver.implicitly_wait(10)
				print(elem.text)
				elem.click()
				html = driver.page_source
				df_course = self.preprocessTable(html)
				
		        # 1.replace pd.null by None 2. transfer to str type
				for row in df_course.iterrows():
					def preprocess(item):
						if pd.isnull(item):
							return None
						else:
							return str(item)
					row = pd.Series(row[1]).apply(preprocess)

					# match columns
					courseItem = UcrawlerItem()
					courseItem['department'] = row['授課對象'] if row['授課對象'] != None else None
					courseItem['for_dept'] =  row['授課對象'] if row['授課對象'] != None else None
					courseItem['obligatory_tf'] = True if row['必選修'] == '必修' else False
					courseItem['grade'] = row['班次'] if row['班次'] != None else None
					courseItem['title'] = row['課程名稱'] if row['課程名稱'] != None else None
					courseItem['note'] =  row['備註'] if row['備註'] != None else None
					courseItem['professor'] = [row['授課教師']] if row['授課教師'] != None else None

					Ctime, location = self.parse_time(row['時間教室'])
					courseItem['time'] = Ctime
					courseItem['location'] = location

					courseItem['credits'] = float(row['學分']) if row['學分'] != None else None
					courseItem['code'] = row['流水號'] if row['流水號'] != None else None
					courseItem['campus'] = 'NTU'
					courseItem['category'] = self.parse_category(row['課號'], row['備註'], self.genEduCodeLi, courseItem['obligatory_tf'])
					yield courseItem



				# self.html = driver.page_source
				# self.htmlparser(self.html)
				# yield TextResponse(url=self.start_urls[0], body=driver.page_source, encoding='utf8')
					## 不知道如何用scrapy的物件傳遞page_source(html)，先用智障的方式處理
		driver.close()

	@classmethod
	def htmlparser(cls, html):
		print("into htmlparser")
		df_course = cls.preprocessTable(html)
		
        # 1.replace pd.null by None 2. transfer to str type
		for row in df_course.iterrows():
			def preprocess(item):
				if pd.isnull(item):
					return None
				else:
					return str(item)
			row = pd.Series(row[1]).apply(preprocess)

			# match columns
			courseItem = UcrawlerItem()
			courseItem['department'] = row['授課對象'] if row['授課對象'] != None else None
			courseItem['for_dept'] =  row['授課對象'] if row['授課對象'] != None else None
			courseItem['obligatory_tf'] = True if row['必選修'] == '必修' else False
			courseItem['grade'] = row['班次'] if row['班次'] != None else None
			courseItem['title'] = row['課程名稱'] if row['課程名稱'] != None else None
			courseItem['note'] =  row['備註'] if row['備註'] != None else None
			courseItem['professor'] = [row['授課教師']] if row['授課教師'] != None else None

			Ctime, location = cls.parse_time(row['時間教室'])
			courseItem['time'] = Ctime
			courseItem['location'] = location

			courseItem['credits'] = float(row['學分']) if row['學分'] != None else None
			courseItem['code'] = row['流水號'] if row['流水號'] != None else None
			courseItem['campus'] = 'NTU'
			courseItem['category'] = cls.parse_category(row['課號'], row['備註'], self.genEduCodeLi, courseItem['obligatory_tf'])
			yield courseItem

	@staticmethod
	def preprocessTable(html, tablecount=6):
		"""table count match table={'共同':7, '系所':6}"""
		df_course = pd.read_html(html ,encoding='utf8')[tablecount]
		df_course.columns= df_course.xs(0)
		df_course = df_course.drop(df_course.index[0])
		# df_course = df_course.where(df_course.notnull(), None)

	    ##remove escape char in the column header
		columns = []
		for column in df_course.columns:
			columns.append(column.replace("/","").replace("查看課程大綱，請點選課程名稱",""))
		df_course.columns = columns

		return df_course

	@classmethod
	def parse_time(cls, timeAndLocation):
		if timeAndLocation != None:
			timeAndLocation = timeAndLocation
			locationMatches = re.findall(r'\(.+?\)', timeAndLocation)
			locationLi = list(pd.Series(locationMatches).apply(lambda x : x.replace("(","").replace(")","")))
			timeMatches = re.findall(r"[一二三四五六]{1}[0-9,A-D]+", timeAndLocation)
			timeMatches = list(pd.Series(timeMatches).apply(lambda x: x.replace("A", "11").replace("B", "12").replace("C", "13").replace("D", "14")))
			timeObjLi = []
			for ctime in timeMatches:
				weekday = re.findall(r"[一二三四五六]{1}", ctime)[0]
				timeObj = {}
				timeObj['day'] = cls.day_table[weekday]
				timeObj['time'] = re.sub(r'[一二三四五六]{1}', "", ctime).split(',')
				timeObjLi.append(timeObj)
		else:
			locationLi = None
			timeObjLi = None
		return timeObjLi, locationLi


	@staticmethod
	def parse_category(courseCode, note, GenEduCodeLi, obligatory_tf):
		"""coursecode 對應到台大的「課號」, GenEduCodeLi指台大官網"共同"項目底下的課程"""
		courseCodeExist = courseCode != None  
		noteExist = note != None
		if courseCodeExist and "PE" in courseCode:
			return "體育類"
		elif (courseCodeExist and (courseCode in GenEduCodeLi or "GenEdu" in courseCode or "MilTr" in courseCode)) or (noteExist and "基本能力課程" in note):
			return "其他類"
		elif noteExist and ("文學與藝術" in note or "歷史思維" in note or "世界文明" in note or "哲學與道德思考" in note or "公民意識與社會分析" in note or "量化分析與數學素養" in note or "物質科學" in note or "生命科學" in note) :
			return "通識類"
		else:
			return "必修類" if obligatory_tf else "選修類"


	@staticmethod
	def sendPageCountAndSubmit(driver, CountPerPage):
		try:
			elem = tryLocateElemById(driver, "page_cnt")
		finally:
			elem.clear()
			elem.send_keys(str(CountPerPage))

		try:
			# Xpath = '/html/body/table[2]/tbody/tr/td/font/table[1]/tbody/tr/td/table/tbody/tr[11]/td[2]/input'
			# elem = tryLocateElemByXpath(driver, Xpath)
			selector = "input[name='Submit22']"
			elem = tryLocateElemBySelector(driver, selector)
		finally:
			elem.click()