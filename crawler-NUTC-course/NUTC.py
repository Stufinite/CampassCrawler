import requests, json, pyprind
from selenium import webdriver
from bs4 import BeautifulSoup
driver = webdriver.Chrome(executable_path="./chromedriver")
# driver = webdriver.PhantomJS(executable_path='./phantomjs')
driver.get('https://aisap.nutc.edu.tw/public/day/course_list.aspx')
soup = BeautifulSoup(driver.page_source)
dept_table = {i.text: i['value'] for i in soup.select('.selgray')[1].select('option')}
latest_semester = soup.select('#sem')[0].select('option')[-1]['value']

result = []
for code in pyprind.prog_bar(dept_table.values()):
	res = requests.get('https://aisap.nutc.edu.tw/public/day/course_list.aspx?sem={}&clsno={}'.format(latest_semester, code), verify=False, headers={'user-agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36'})
	soup = BeautifulSoup(res.text)

	schema, course = soup.select('.empty_html tr')[0], soup.select('.empty_html tr')[1:]
	schema = tuple(i.text for i in schema.select('th'))
	data = tuple(map(lambda result: dict(zip(schema, result)), tuple(map(lambda c:tuple(map(lambda x:x.text, c.select('td'))), course))))
	result += data
driver.close()

json.dump(result, open('NUTC.json','w'))