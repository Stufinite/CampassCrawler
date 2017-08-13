import requests
from bs4 import BeautifulSoup
import re
from pprint import pprint
from UCrawler.items import UcrawlerItem
import pandas as pd
import scrapy
from scrapy.http import Request, FormRequest



class NtpuSpider(scrapy.Spider):
	name = 'SCU'
	start_urls = ['https://web.sys.scu.edu.tw/class401.asp']
	headers = {'user-agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36','referer':'http://www.ntpu.edu.tw/chinese/'}
	day_table = {
		'一':1,
		'二':2,
		'三':3,
		'四':4,
		'五':5,
		'六':6
		}
	failMasters = []

	def start_requests(self):
		res = requests.get(self.start_urls[0])
		res.encoding = 'big5'
		soup = BeautifulSoup(res.text, 'lxml')

		## Beacause it distinguish only master column
		masters = []
		start = False
		for script in soup.find_all("script"):
		    if '//v4.0' in str(script):
		        if '人社院' in str(script):
		            start = True
		        if start:
		            lines = script.text.split()
		            for line in lines:
		                if "=" in line:
		                    master = line.split("=")[1].replace("\"","").replace(";","")
		                    if bool(re.match(r'\d', master)):
		                        masters.append(master)
		for master in masters:
			## clsid02 系所不會被引擎索引，所以不需要變動
			url = "https://web.sys.scu.edu.tw/class42.asp"
			data = {
				'clsid1': "1學士班".encode("big5"),
				'clsid02': "1111中國文學系".encode("big5"),
				'clsid34':master.encode("big5"),
				'syear':"106",
				'smester':"1"
				}
			yield scrapy.FormRequest(url, formdata=data, encoding='big5', headers=self.headers, meta={'master': master})
		print("無課表資料:", self.failMasters)

	def parse(self, response):
		## blocked
		if len(response.body) == 548:
			self.failMasters.append(response.meta['master'])
		else:
			try:
				df_course = pd.read_html(response.body)[0]
			except:
				self.failMasters.append(response.meta['master'])
				raise Exception("No Table Found")
			##drop coursename == null
			df_course.drop(df_course[pd.isnull(df_course[3])].index,inplace=True)

			##Exchage first row with column
			columns = []
			for column in list(df_course.xs(0)):
				column = re.findall(r'[\u4e00-\u9fa5]+', column)[0]
				columns.append(column)
			df_course.columns = columns
			df_course.drop(0, inplace=True)

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
				courseItem['department'] = row['開課班級'] if row['開課班級'] != None else None
				courseItem['for_dept'] =  row['開課班級'] if row['開課班級'] != None else None
				courseItem['obligatory_tf'] = True if row['修選別'] == '必' else False
				courseItem['grade'] = row['開課班級'] if row['開課班級'] != None else None
				courseItem['title'] = row['科目名稱'] if row['科目名稱'] != None else None
				courseItem['note'] =  row['備註'] if row['備註'] != None else None
				courseItem['professor'] = self.parse_teacher(row['授課教師'])

				courseItem['time'] = self.parse_time(row['星期'], row['節次'])
				courseItem['location'] = [row['教室']] if row['教室'] != None else None

				courseItem['credits'] = float(row['學分數']) if row['學分數'] != None else None
				courseItem['code'] = row['選課編號'] if row['選課編號'] != None else None
				courseItem['campus'] = 'SCU'
				courseItem['category'] = self.parse_category(courseItem['department'], row['組別'], courseItem['title'], courseItem['obligatory_tf'])
				yield courseItem



	@classmethod
	def parse_time(cls, cday, ctime):
		processedTimeLi = []
		if cday == None or ctime == None:
			processedTimeLi = None
		else:
			timeObj = {}
			timeObj['day'] = cls.day_table.get(cday)
			## "E" is noon
			ctime = str(ctime).replace("E", "")
			timeLi = [time.replace("A", "10").replace("B", "11").replace("C", "12").replace("D", "13") for time in ctime]
			timeObj['time'] = timeLi
			processedTimeLi.append(timeObj)
		return processedTimeLi

	@staticmethod
	def parse_teacher(teacher):
		teacherLi = []
		if teacher != None:
			if "�".encode('utf8') in teacher.encode('utf8'):
				teacher = teacher.encode("utf8")
				teacher = teacher.replace("陳宣��".encode("utf8"),"陳宣𡞲".encode("utf8")).replace("蔡茜�J".encode("utf8"),"蔡茜𨧤".encode("utf8"))
				teacher = teacher.replace("�d本祐子".encode("utf8"),"𥮴本祐子".encode("utf8")).replace("彥�鰿K乃".encode("utf8"),"彥啝春乃".encode("utf8"))
				teacher = teacher.replace("�騢眲P".encode("utf8"),"幵福星".encode("utf8")).replace("林�P志".encode("utf8"),"林杄志".encode("utf8"))
				teacher = teacher.replace("陳碧�H".encode("utf8"),"陳碧㙉".encode("utf8")).replace("陳 �M".encode("utf8"),"陳 苮".encode("utf8"))
				teacher = teacher.replace("林書�J".encode("utf8"),"林書𨧤".encode("utf8")).replace("呂明��".encode("utf8"),"呂明𤪦".encode("utf8"))
				teacher = teacher.replace("�Q麗明".encode("utf8"),"拟麗明".encode("utf8")).replace("吳��霙".encode("utf8"),"吳㳫霙".encode("utf8"))
				teacher = teacher.replace("呂秋�F".encode("utf8"),"呂秋弍".encode("utf8"))
				teacher = teacher.decode('utf8')
			teacherLi.extend(re.findall(r"[\u4e00-\u9fa5]{2,4}", teacher))
			teacherLi.extend(re.findall(r"[\u4e00-\u9fa5]{1}[ ]{1}[\u4e00-\u9fa5]{1}", teacher))
		else:
			teacherLi = None
		return teacherLi

	@staticmethod
	def parse_category(className, group, title, obligatory_tf):
		"""className=開課班級, group=組別, title=課程名稱"""
		classNameExist = className!=None
		groupExist = group!=None
		if "體育" in title or (classNameExist and "體育" in className):
			return "體育類"
		elif (groupExist and"通識" in group) or  className in ["溪通識一","溪通識二","城通識二","溪通識三","城通識三","遠距通識"]:
			return "通識類"
		elif className in ["全校選修","溪國文","溪英文(一)","溪日文(一)","溪德文(一)","城英文(一)","城日文(一)","城德文(一)","溪英文(二)","溪日文(二)","溪德文(二)","城英文(二)","城日文(二)","城德文(二)","溪法治","城法治","溪歷史"]:
			return "其他類"
		else:
			return "必修類" if obligatory_tf else "選修類"





