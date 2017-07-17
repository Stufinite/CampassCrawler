import requests, json, pyprind, re
from selenium import webdriver
from bs4 import BeautifulSoup
res = requests.get('http://selcrs.nsysu.edu.tw/menu1/qrycourse.asp')
res.encoding = 'big5'
soup = BeautifulSoup(res.text, "html.parser")

dept_table = {i.text:i['value'] for i in soup.select('#DPT_ID select')[0] if i.text != '' and (i['value'].startswith('A') or i['value'].startswith('B'))}
latest_semester = soup.find('select', {'name':'D0'}).select('option')[0]['value']

day_table = {
	'一':1,
	'二':2,
	'三':3,
	'四':4,
	'五':5,
	'六':6,
	'日':7,
}

final = []
for key, value in pyprind.prog_bar(dept_table.items()):
	res = requests.get("http://selcrs.nsysu.edu.tw/menu1/dplycourse.asp?a=1&D0={semester}&DEG_COD={degree}&D1={deptcode}&HIS=1&TYP=1&bottom_per_page=10&data_per_page=20".format(semester=latest_semester, degree=value[0], deptcode=value))
	res.encoding = 'big5'	
	soup = BeautifulSoup(res.text, "html.parser")

	last_page = int(re.search(r"\/(.+?)頁",  soup.select('td')[-1].text).group(1).strip())
	for page in range(1, last_page+1):

		driver = webdriver.PhantomJS(executable_path='../phantomjs')
		driver.get("http://selcrs.nsysu.edu.tw/menu1/dplycourse.asp?a=1&D0={semester}&DEG_COD={degree}&D1={deptcode}&HIS=1&TYP=1&bottom_per_page=10&data_per_page=20&page={page}".format(semester=latest_semester, degree=value[0], deptcode=value, page=str(page)))
		soup = BeautifulSoup(driver.page_source, "html.parser")

		schema, weekdays, course = [i.text for i in soup.select('tr')[1].select('td')], [i.text for i in soup.select('tr')[2].select('td')], soup.select('tr')[3:-2]
		schema = schema[:-2] + weekdays + schema[-1:]
		for courseDict in (dict(zip(schema, (j.text for j in i.select('td')[1:]))) for i in course):
			result = {
				'department': key,
				'for_dept':courseDict['系所別'],
				'class':courseDict['年級'],
				'title_parsed':courseDict['科目名稱'],
				'time':[{'day':day_table[time], 'time':list(courseDict[time])} for time in courseDict if time in day_table and courseDict[time]!='\xa0'],
				'credits':float(courseDict['學分']),
				'obligatory_tf':True if courseDict['必選修'] == '必' else False,
				'professor':courseDict['授課教師'],
				'location':courseDict['教室'],
				'code':courseDict['課號'],
				'note':courseDict['備註'],
			}

			final.append(result)


json.dump(final, open('nsysu.json', 'w'))