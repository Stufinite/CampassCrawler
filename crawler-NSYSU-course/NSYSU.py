import requests, json, pyprind, re
from selenium import webdriver
from bs4 import BeautifulSoup
res = requests.get('http://selcrs.nsysu.edu.tw/menu1/qrycourse.asp')
res.encoding = 'big5'
soup = BeautifulSoup(res.text, "html.parser")

dept_table = {i.text:i['value'] for i in soup.select('#DPT_ID select')[0] if i.text != ''}
latest_semester = soup.find('select', {'name':'D0'}).select('option')[0]['value']

result = []
for i in pyprind.prog_bar(dept_table.values()):
	res = requests.get("http://selcrs.nsysu.edu.tw/menu1/dplycourse.asp?a=1&D0={semester}&DEG_COD={degree}&D1={deptcode}&HIS=1&TYP=1&bottom_per_page=10&data_per_page=20".format(semester=latest_semester, degree=i[0], deptcode=i))
	res.encoding = 'big5'	
	soup = BeautifulSoup(res.text, "html.parser")

	last_page = int(re.search(r"\/(.+?)頁",  soup.select('td')[-1].text).group(1).strip())
	for page in range(1, last_page+1):

		driver = webdriver.PhantomJS(executable_path='../phantomjs')
		driver.get("http://selcrs.nsysu.edu.tw/menu1/dplycourse.asp?a=1&D0={semester}&DEG_COD={degree}&D1={deptcode}&HIS=1&TYP=1&bottom_per_page=10&data_per_page=20&page={page}".format(semester=latest_semester, degree=i[0], deptcode=i, page=str(page)))
		soup = BeautifulSoup(driver.page_source, "html.parser")

		schema, weekdays, course = [i.text for i in soup.select('tr')[1].select('td')], [i.text for i in soup.select('tr')[2].select('td')], soup.select('tr')[3:-2]
		schema = schema[:-2] + weekdays + schema[-1:]
		result += tuple(map(lambda row:dict(zip(schema, row)), [ tuple(j.text for j in i.select('td'))[1:] for i in course]))
		
json.dump(result, open('nsysu.json', 'w'))