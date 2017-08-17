# -*- coding: utf-8 -*-
import scrapy, json
from UCrawler.items import UcrawlerItem

class NchuSpider(scrapy.Spider):
    name = 'NCHU'
    allowed_domains = ['onepiece.nchu.edu.tw']
    start_urls = [
        'https://onepiece.nchu.edu.tw/cofsys/plsql/json_for_course?p_career=U',
        'https://onepiece.nchu.edu.tw/cofsys/plsql/json_for_course?p_career=O'
    ]

    genra = {
        '通識教育中心':'通識類',
        '體育室':'體育類',
        '教官室':'其他類',
        '師資培育中心':'其他類'
    }

    TrueFalseTable = {
        True:"必修類",
        False:"選修類"
    }


    def parse(self, response):
        try:
            dataList = json.loads(response.text)
        except Exception as e:
            try:
                dataList = json.loads(self.validateTmpJson(response.text))
            except Exception as e:
                print(e)    
                raise e

        for data in dataList['course']:
            courseItem = UcrawlerItem()
            courseItem['department'] = data['department']
            courseItem['grade'] = data['class']
            courseItem['for_dept'] = data['for_dept']
            courseItem['credits'] = data['credits']
            courseItem['obligatory_tf'] = data['obligatory_tf']
            courseItem['professor'] = data['professor']
            courseItem['location'] = data['location']
            courseItem['time'] = data['time_parsed']
            courseItem['code'] = data['code']
            courseItem['note'] = data['note']
            courseItem['campus'] = 'NCHU'
            courseItem['discipline'] = data['discipline']
            courseItem['title'] = data['title_parsed']['zh_TW']
            courseItem['category'] = self.genra.get(courseItem['department'], '其他類' if courseItem['for_dept'] == '全校共同' else self.TrueFalseTable[courseItem['obligatory_tf']])
            yield courseItem

    @staticmethod
    def validateTmpJson(tmpJson):
        def truncateNewLineSpace(line):
            tmp = ""
            for i in line:
                if i != "\n" and i != " ":
                    tmp+=i
            return tmp
        # truncate invalid char to turn it into json
        jsonStr = ""
        for line in tmpJson:
            tmp = truncateNewLineSpace(line)
            jsonStr +=tmp
        return jsonStr