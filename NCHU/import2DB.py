#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json, pymongo
class import2Mongo(object):
	"""docstring for import2Mongo"""
	def __init__(self, uri=None):
		from pymongo import MongoClient

		self.JSONdir = 'json'
		self.degree2Chi = {"U":'學士班', "G":'碩士班',"D":'博士班',"N":'進修學士班',"W":'碩專班', "O":'全校共同'}
		self.deptSet = set()
		self.client = MongoClient(uri)
		self.db = self.client['timetable']
		self.DeptCollect = self.db['CourseOfDept']
		self.CourseOfTime = self.db['CourseOfTime']
		self.DeptCollect.remove({})
		self.CourseOfTime.remove({})

		self.chgTable = dict(tuple((dept['name'], dept['value']) for degree in json.load(open('fallback/json/department.json', 'r')) for dept in degree['department']))
		self.degreeTable = {}
		for degree in json.load(open('fallback/json/department.json', 'r')):
			for d in degree['department']:
				self.degreeTable.setdefault(d['name'], []).append(degree['degree'])

	def AddHeader(self, document, degree):
		document['degree'] = degree
		document['school'] = NCHU
		return document

	def getDeptCode(self, deptName, grade):
		if len(grade) > 1:
			deptName = deptName + ' ' + grade[-1].upper()
		return self.chgTable.get(deptName, False)

	def BuildByDept(self, jsonDict):
		def getClass(grade):
			if len(grade) == 1:
				return 'ClassA', grade
			if grade == "":
				return 'ClassA', '0'
			return 'Class'+str.capitalize(grade[-1]), grade[0]

		def getObliAttr(obligat):
			if obligat:
				return 'obligatory'
			return 'optional'

		result = {}
		for i in jsonDict:
			dept = self.getDeptCode(i['for_dept'], i['class'])
			# dept == False means getDeptCode has error
			if dept == False: 
				print(i['for_dept'], i['class'])
				continue
			code = i['code']
			grade = i['class']
			className, grade = getClass(grade)
			obligat = i['obligatory_tf']
			oblAttr = getObliAttr(obligat)

			result.setdefault(dept, 
				{
					'obligatory':{},
					'optional':{}
				}
			)

			result[dept][oblAttr].setdefault(grade, []).append(code)

		resultList = tuple( dict(dept=dept, course=course, school='NCHU') for dept, course in result.items())
		self.DeptCollect.insert(resultList)
		self.CourseOfTime.create_index([("school", pymongo.ASCENDING),("dept", pymongo.ASCENDING)])

	def BuildByTime(self, jsonDict):
		result = {
			1:{1:{},2:{},3:{},4:{},5:{},6:{},7:{},8:{},9:{},10:{},11:{},12:{},13:{}},
			2:{1:{},2:{},3:{},4:{},5:{},6:{},7:{},8:{},9:{},10:{},11:{},12:{},13:{}},
			3:{1:{},2:{},3:{},4:{},5:{},6:{},7:{},8:{},9:{},10:{},11:{},12:{},13:{}},
			4:{1:{},2:{},3:{},4:{},5:{},6:{},7:{},8:{},9:{},10:{},11:{},12:{},13:{}},
			5:{1:{},2:{},3:{},4:{},5:{},6:{},7:{},8:{},9:{},10:{},11:{},12:{},13:{}},
			6:{1:{},2:{},3:{},4:{},5:{},6:{},7:{},8:{},9:{},10:{},11:{},12:{},13:{}},
			7:{1:{},2:{},3:{},4:{},5:{},6:{},7:{},8:{},9:{},10:{},11:{},12:{},13:{}}
		}
		for course in jsonDict:
			for time in course['time_parsed']:
				day = time['day']
				for t in time['time']:
					for degree in self.degreeTable.setdefault(course['for_dept'], []):
						result[day][t].setdefault(degree, {}).setdefault(self.getDeptCode(course['for_dept'], course['class']), []).append(course['code'])

		resultList = tuple(dict(school='NCHU', day=d, time=t, value=codeArr) for d in result for t, codeArr in result[d].items())
		self.CourseOfTime.insert(resultList)
		self.CourseOfTime.create_index([("school", pymongo.ASCENDING),("day", pymongo.ASCENDING), ('time',pymongo.ASCENDING)])

	def save2DB(self):
		def getJson(degree):
			return json.load(open(self.JSONdir+'/'+degree+'.json', 'r', encoding='utf8'))
		AllJson = tuple(_ for degree in self.degree2Chi for _ in getJson(degree)['course'])

		self.BuildByDept(AllJson)
		self.BuildByTime(AllJson)