# -*- coding: utf-8 -*-
import scrapy, json, pyprind, re, time, os
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup
from UCrawler.items import UcrawlerItem
from .setting_selenium import cross_selenium

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

    genra = {
        '通識':'通識類',
        '體育':'體育類',
        '語言':'其他類'
    }

    def start_requests(self):
        driver = cross_selenium()
        # driver = cross_selenium(True)
        driver.get(self.start_urls[0])
        try:
            element = WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.ID, "sem"))
            )
        finally:
            # dropdown = driver.find_element_by_id('sem')
            dropdown = driver.find_element_by_id('//*[@id="sem"]')
            option = dropdown.find_elements_by_tag_name("option")
            option[-1].click()
            time.sleep(3)
            soup = BeautifulSoup(driver.page_source, "html.parser")
            driver.close()

        dept_table = {i.text: i['value'] for i in soup.select('.selgray')[1].select('option') if '所' not in i.text and '專' not in i.text}
        latest_semester = soup.select('#sem')[0].select('option')[-1]['value']

        for code in pyprind.prog_bar(dept_table.values()):
            yield scrapy.Request('https://aisap.nutc.edu.tw/public/day/course_list.aspx?sem={}&clsno={}'.format(latest_semester, code), self.parse)

    def parse(self, response):
        soup = BeautifulSoup(response.body, "html.parser")

        schema, course = soup.select('.empty_html tr')[0], soup.select('.empty_html tr')[1:]
        schema = tuple(i.text for i in schema.select('th'))
        # dataList = tuple(map(lambda result: dict(zip(schema, result)), tuple(map(lambda c:tuple(map(lambda x:x.text, c.select('td'))), course))))
        dataList = (dict(zip(schema, result)) for result in (tuple(x.text for x in c.select('td')) for c in course))

        for data in dataList:
            courseItem = UcrawlerItem()
            courseItem['department'], courseItem['grade'] = data['開課班級'][:[data['開課班級'].find(i) for i in '一二三四五' if data['開課班級'].find(i) != -1][0]], data['開課班級'][[data['開課班級'].find(i) for i in '一二三四五' if data['開課班級'].find(i) != -1][0]:]
            courseItem['for_dept'] = courseItem['department']
            courseItem['credits'] = float(data['時數 / 學分'].split('/')[-1])
            courseItem['obligatory_tf'] = True if data['修別'] == '必' else False
            courseItem['professor'] = data['上課教師']
            courseItem['location'] = re.findall(r'(\(.+?\))', data['上課時間/教室'])
            courseItem['time'] = self.parse_time(data['上課時間/教室'].split('/'), courseItem['location'])
            courseItem['code'] = data['課程代碼']
            courseItem['note'] = data['組別']
            courseItem['campus'] = 'NUTC'
            courseItem['discipline'] = re.search(r'\((.+?)\)', data['課程']).group(1) if self.genra.get(courseItem['department'], '') == '通識類' else ''
            courseItem['title'] = data['課程'].replace(re.search(r'\((.+?)\)', data['課程']).group(0), '').strip() if self.genra.get(courseItem['department'], '') == '通識類' else data['課程']
            courseItem['category'] = self.genra.get(courseItem['department'], '必修類' if courseItem['obligatory_tf'] else '選修類')
            yield courseItem

    @classmethod
    def parse_time(cls, time_list, location_list):
        tmpTime = [time.replace(location, '').strip() for time, location in list(zip(time_list, location_list))]
        tmpTime = [dict(day=cls.day_table[t[2]], time=re.search(r'第(.+?)節', t).group(1) ) for t in tmpTime]
        for i in tmpTime:
            if len(i['time']) == 1:
                i['time'] = [int(i['time'])]
            elif '、' in i['time']:
                i['time'] = [int(i) for i in i['time'].split('、')]
            else:
                i['time'] = tuple(range(int(i['time'].split('～')[0]), int(i['time'].split('～')[1])+1))
        return tmpTime
