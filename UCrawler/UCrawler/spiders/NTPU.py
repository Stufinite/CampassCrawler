# -*- coding: utf-8 -*-
import scrapy


class NtpuSpider(scrapy.Spider):
    name = 'NTPU'
    allowed_domains = ['sea.cc.ntpu.edu.tw']
    start_urls = ['https://sea.cc.ntpu.edu.tw/pls/dev_stud/course_query_all.CHI_query_Common']

    def start_requests(self):
        url = 'https://sea.cc.ntpu.edu.tw/pls/dev_stud/course_query_all.CHI_query_common'
        headers = {'user-agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36','referer':'http://www.ntpu.edu.tw/chinese/'}
        yield scrapy.Request(url, method='GET', encoding='utf8',headers = headers)

    def parse(self, response):
        soup = BeautifulSoup(response.body, 'lxml')
        elem = soup.find('select')
        schoolList = []
        for item in elem.find_all('option'):
            schoolList.append(item.string)
            print(item.string)
        schoolList.pop(0)
