# -*- coding: utf-8 -*-
import scrapy, json, pyprind
from selenium import webdriver
from bs4 import BeautifulSoup
from UCrawler.items import UcrawlerItem

class NutcSpider(scrapy.Spider):
    name = 'NUTC'
    allowed_domains = ['aisap.nutc.edu.tw']
    start_urls = ['https://aisap.nutc.edu.tw/public/day/course_list.aspx']

    def start_requests(self):
        driver = webdriver.Chrome(executable_path="./chromedriver")
        driver.get(self.start_urls[0])
        soup = BeautifulSoup(driver.page_source, "html.parser")
        dept_table = {i.text: i['value'] for i in soup.select('.selgray')[1].select('option')}
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
            courseItem['department'] = data['開課班級']
            courseItem['for_dept'] = data['開課班級']
            courseItem['grade'] = data['開課班級']
            courseItem['title_parsed'] = data['課程']
            courseItem['time'] = data['上課時間/教室']
            courseItem['credits'] = float(data['時數 / 學分'].split('/')[-1])
            courseItem['obligatory_tf'] = True if data['修別'] == '必' else False
            courseItem['professor'] = data['上課教師']
            courseItem['location'] = data['上課時間/教室'].split('/')[-1]
            courseItem['code'] = data['課程代碼']
            courseItem['note'] = data['組別']
            yield courseItem