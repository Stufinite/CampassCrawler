# -*- coding: utf-8 -*-
import scrapy
import requests, json, pyprind, re, os
from selenium import webdriver
from bs4 import BeautifulSoup
from UCrawler.items import UcrawlerItem
from .setting_selenium import cross_selenium


class NsysuSpider(scrapy.Spider):
	name = 'NSYSU'
	allowed_domains = ['selcrs.nsysu.edu.tw/']
	start_urls = ['http://selcrs.nsysu.edu.tw/menu1/qrycourse.asp']
	driver = cross_selenium()
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
		'A':0,
		'C':10,
		'D':11,
		'E':12,
		'F':13
	}

	genra = {
		'通識教育':'通識類',
		'通識教育(向度)':'通識類',
		'運動健康(必)':'體育類',
		'運動進階(選)':'體育類',
		'中學學程':'其他類',
		'進修英文':'其他類',
		'國語文':'其他類',
		'英文初級':'其他類',
		'英文中級':'其他類',
		'英文中高級':'其他類',
		'英文高級':'其他類',
		'中學學程':'其他類',
		'中學學程':'其他類',
		'中學學程':'其他類',
		'中學學程':'其他類',
		'中學學程':'其他類',
		'校際(學士班)':'其他類',
		'普通物理小組':'其他類',
		'應用性課程':'其他類',
		'跨院選修(文)':'其他類',
		'跨院選修(理)':'其他類',
		'跨院選修(工)':'其他類',
		'跨院選修(管)':'其他類',
		'跨院選修(海)':'其他類',
		'跨院選修(社)':'其他類',
		'服務學習':'其他類',
	}

	def start_requests(self):
		res = requests.get(self.start_urls[0])
		res.encoding = 'big5'
		soup = BeautifulSoup(res.text, "html.parser")

		dept_table = {i.text:i['value'] for i in soup.select('#DPT_ID select')[0] if i.text != '' and (i['value'].startswith('A') or i['value'].startswith('B')) and '院' not in i.text}
		latest_semester = soup.find('select', {'name':'D0'}).select('option')[0]['value']

		for key, value in dept_table.items():
			yield scrapy.Request("http://selcrs.nsysu.edu.tw/menu1/dplycourse.asp?a=1&D0={semester}&DEG_COD={degree}&D1={deptcode}&HIS=1&TYP=1&bottom_per_page=10&data_per_page=20".format(semester=latest_semester, degree=value[0], deptcode=value), self.parse, meta={'key': key})

	def parse(self, response):
		soup = BeautifulSoup(response.body, "html.parser")
		last_page = int(re.search(r"\/(.+?)頁",  soup.select('td')[-1].text).group(1).strip())

		for page in range(1, last_page+1):
			self.driver.get(response.url + '&page=' + str(page))
			soup = BeautifulSoup(self.driver.page_source, "html.parser")

			schema, weekdays, course = [i.text for i in soup.select('tr')[1].select('td')], [i.text for i in soup.select('tr')[2].select('td')], soup.select('tr')[3:-2]
			schema = schema[:-2] + weekdays + schema[-1:]
			for courseDict in (dict(zip(schema, (j.text for j in i.select('td')[1:]))) for i in course):
				courseItem = UcrawlerItem()
				courseItem['department'] = response.meta['key']
				courseItem['for_dept'] = courseDict['系所別']
				courseItem['grade'] = courseDict['年級']
				courseItem['title'] = courseDict['科目名稱']

				# courseDict[time].replace('B', '') 是因為B代表中午時段，我們的課表沒有中午這格可以放 0.0
				courseItem['time'] = [{'day':self.day_table[time], 'time':[self.time_table[i] if i in self.time_table else i for i in list(courseDict[time].replace('B', ''))]} for time in courseDict if time in self.day_table and courseDict[time]!='\xa0']
				courseItem['credits'] = float(courseDict['學分'])
				courseItem['obligatory_tf'] = True if courseDict['必選修'] == '必' else False
				courseItem['professor'] = courseDict['授課教師']
				courseItem['location'] = courseDict['教室']
				courseItem['code'] = courseDict['課號']
				courseItem['note'] = courseDict['備註']
				courseItem['campus'] = 'NSYSU'
				courseItem['discipline'] = courseItem['for_dept'] if self.genra.get(courseItem['department'], '') == '通識類' else ''
				courseItem['category'] = self.genra.get(courseItem['department'], '大學部')
				yield courseItem