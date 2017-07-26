# -*- coding: utf-8 -*-
import scrapy


class NtpuSpider(scrapy.Spider):
    name = 'NTPU'
    allowed_domains = ['sea.cc.ntpu.edu.tw']
    start_urls = ['https://sea.cc.ntpu.edu.tw/pls/dev_stud/course_query_all.CHI_query_Common']

    def parse(self, response):
        print(response.body)
