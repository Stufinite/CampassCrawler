#!/usr/bin/env python3
import requests, json, subprocess

class Crawler(object):
	"""docstring for Crawler"""
	def __init__(self):
		self.degree = ['U', 'G', 'D', 'N', 'O', 'W']
		self.url = 'https://onepiece.nchu.edu.tw/cofsys/plsql/json_for_course?p_career='
		self.errCourse = {
			"U":[],
			"G":[],
			"D":[],
			"N":[],
			"O":[],
			"W":[]
		}
		try:
			subprocess.call(['rm', '-rf', 'json'])
			subprocess.call(['mkdir', 'json'])
		except:
			print('path error, the file will be dump into the current directory')

	def truncateNewLineSpace(self, line):
		tmp = ""
		for i in line:
			if i != "\n" and i != " ":
				tmp+=i
		return tmp

	def validateTmpJson(self, tmpFile, degree):
		# truncate invalid char to turn it into json
		jsonStr = ""
		with open('json/'+tmpFile, 'r', encoding='UTF-8') as f:
			for line in f:
				tmp = self.truncateNewLineSpace(line)
				jsonStr +=tmp
		jsonStr = self.checkDegree(jsonStr, degree)
		return jsonStr

	def checkDegree(self, jsonStr, degree):
		# correct those Course which were placed in wrong degree dict.
		jsonDict = json.loads(jsonStr)
		degreeTable = {"U":["1","2","3","4","5","1A","1B","2A","2B","3A","3B", "4A", "4B", "5A", "5B"],"G":["6", "7"], "D":["8", "9"], "N":["1","2","3","4","5"],"O":["0","1","2","3","4","5"], "W":["6", "7"]}
		cleanDict = {'course':[]}
		for index, value in enumerate(jsonDict['course']):
			if value['class'] not in degreeTable[degree]:
				if value['class'] in degreeTable['D']:
					self.errCourse['D'].append(value)
				elif '在職' in value['for_dept'] or '碩士專班' in value['for_dept']:
					self.errCourse['W'].append(value)
				elif '碩士' in value['for_dept'] :
					self.errCourse['G'].append(value)
				elif '進修' in value['for_dept']:
					self.errCourse['N'].append(value)
				elif value['class'] in degreeTable['U']:
					self.errCourse['U'].append(value)
				elif value['class'] == 0 or value['for_dept'].find('全校共同')!=-1:
					self.errCourse['O'].append(value)
				elif '研究所' in value['for_dept']:
					self.errCourse['G'].append(value)
				else:
					print(value)
					raise Exception('clean ERR')
			elif degree == 'G':
				if '碩士專班' in value['for_dept']:
					self.errCourse['W'].append(value)
				else:
					cleanDict['course'].append(value)
			else:
				cleanDict['course'].append(value)

		return json.dumps(cleanDict)

		
	def start(self):
		for d in self.degree:
			re = requests.get(self.url + d)
			re.raise_for_status()#if request has something wrong, like status code 4xx or 5xx, then it will raise an exception.

			formalFile = d + '.json'

			try:
				# dump json file, cannot ensure it's valid json. If fail, it will raise exception and then use self.validateTmpJson functin
				with open('json/'+formalFile, 'w', encoding='UTF-8') as f:
					json_str = json.dumps(re.json(), ensure_ascii=False, sort_keys=True)
					#re.json() will check whether 're' is type of json
					#json.dumps will return string.
					json_str = self.checkDegree(json_str, d)
					f.write(json_str)#f.write only accept and write string into files.
			except Exception as e:
				tmpFile = d + '_tmp.json'
				with open('json/'+tmpFile, 'w', encoding='UTF-8') as f:
					f.write(re.text)

				jsonStr = self.validateTmpJson(tmpFile, d)
				try:
					testJsonvalid=json.loads(jsonStr)
					formalFile = d + '.json'
					with open('json/'+formalFile, 'w', encoding='UTF-8') as f:
						f.write(jsonStr)
				except Exception as e:
					print(e)    
					raise e    

		for key, value in self.errCourse.items():
			# with open(key+".json.error", 'w', encoding='utf-8') as f:
			# 	json.dump(value, f)
			with open("json/"+key+".json", 'r', encoding='utf-8') as f:
				tmp = json.load(f)
				for i in self.errCourse[key]:
					tmp['course'].append(i)
			with open("json/"+key+".json", 'w', encoding='utf-8') as f:
				json.dump(tmp, f)