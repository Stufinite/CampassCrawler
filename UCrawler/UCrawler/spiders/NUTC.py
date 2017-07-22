# -*- coding: utf-8 -*-
import scrapy, json, pyprind, re, time
from selenium import webdriver
from bs4 import BeautifulSoup
from UCrawler.items import UcrawlerItem

class NutcSpider(scrapy.Spider):
    name = 'NUTC'
    allowed_domains = ['aisap.nutc.edu.tw']
    start_urls = ['https://aisap.nutc.edu.tw/public/day/course_list.aspx']
    day_table = {
        '一':1,
        '二':2,
        '三':3,
        '四':4,
        '五':5,
        '六':6,
        '日':7,
    }

    def start_requests(self):
        driver = webdriver.Chrome(executable_path="./chromedriver")
        driver.get(self.start_urls[0])
        dropdown = driver.find_element_by_id('sem')
        option = dropdown.find_elements_by_tag_name("option")
        option[-1].click()
        time.sleep(3)
        soup = BeautifulSoup(driver.page_source, "html.parser")
        dept_table = {i.text: i['value'] for i in soup.select('.selgray')[1].select('option') if '所' not in i.text and '專' not in i.text}
        latest_semester = soup.select('#sem')[0].select('option')[-1]['value']

        for code in pyprind.prog_bar(dept_table.values()):
            yield scrapy.Request('https://aisap.nutc.edu.tw/public/day/course_list.aspx?sem={}&clsno={}'.format(latest_semester, code), self.parse)

    def parse(self, response):
        soup = BeautifulSoup(response.body, "html.parser")

        schema, course = soup.select('.empty_html tr')[0], soup.select('.empty_html tr')[1:]
        schema = tuple(i.text for i in schema.select('th'))
        dataList = tuple(map(lambda result: dict(zip(schema, result)), tuple(map(lambda c:tuple(map(lambda x:x.text, c.select('td'))), course))))
        for data in dataList:
            courseItem = UcrawlerItem()
            courseItem['department'], courseItem['grade'] = data['開課班級'][:[data['開課班級'].find(i) for i in '一二三四五' if data['開課班級'].find(i) != -1][0]], data['開課班級'][[data['開課班級'].find(i) for i in '一二三四五' if data['開課班級'].find(i) != -1][0]:]
            courseItem['for_dept'] = courseItem['department']
            courseItem['title'] = data['課程']
            courseItem['credits'] = float(data['時數 / 學分'].split('/')[-1])
            courseItem['obligatory_tf'] = True if data['修別'] == '必' else False
            courseItem['professor'] = data['上課教師']
            courseItem['location'] = re.findall(r'(\(.+?\))', data['上課時間/教室'])

            tmpTime = [time.replace(location, '').strip() for time, location in list(zip(data['上課時間/教室'].split('/'), courseItem['location']))]
            tmpTime = [dict(day=self.day_table[t[2]], time=re.search(r'第(.+?)節', t).group(1) ) for t in tmpTime]
            for i in tmpTime:
                if len(i['time']) == 1:
                    i['time'] = [int(i['time'])]
                elif '、' in i['time']:
                    i['time'] = [int(i) for i in i['time'].split('、')]
                else:
                    i['time'] = tuple(range(int(i['time'].split('～')[0]), int(i['time'].split('～')[1])+1))
            courseItem['time'] = tmpTime

            courseItem['code'] = data['課程代碼']
            courseItem['note'] = data['組別']
            courseItem['campus'] = 'NUTC'
            yield courseItem