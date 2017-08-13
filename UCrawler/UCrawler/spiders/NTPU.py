# -*- coding: utf-8 -*-
import scrapy
from scrapy.http import Request, FormRequest
from bs4 import BeautifulSoup
import requests
from selenium import webdriver
import pandas as pd
import json
import re
from UCrawler.items import UcrawlerItem

class NtpuSpider(scrapy.Spider):
    name = 'NTPU'
    #allowed_domains = ['sea.cc.ntpu.edu.tw']
    #start_urls = ['https://sea.cc.ntpu.edu.tw/pls/dev_stud/course_query_all.queryByAllConditions']
    #driver = webdriver.Chrome(executable_path='D:\chromedriver')
    #headers = {'user-agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36'}
    headers = {'user-agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36','referer':'http://www.ntpu.edu.tw/chinese/'}

    def start_requests(self):
        url = 'https://sea.cc.ntpu.edu.tw/pls/dev_stud/course_query_all.CHI_query_common'
        re = requests.get(url, headers = self.headers)
        soup = BeautifulSoup(re.text, 'lxml')
        postpath = 'https://sea.cc.ntpu.edu.tw/pls/dev_stud/course_query_all.queryByAllConditions'

        ## College based finder
        elem = soup.find('select')
        schoolList = []
        for item in elem.find_all('option'):
            schoolList.append(item.string)
            print(item.string)
        schoolList.pop(0)

        for school in schoolList:
            print(school)
            FormData = {
            'qCollege': school.encode('big5'),
            'qYear':'106',
            'qTerm':'1',
            'seq1':'A',
            'seq2':'M'
            }
            #This fail
            #request_body = json.dumps(FormData)
            #yield Request(postpath, method= "POST", body=request_body, headers=self.headers )
            yield scrapy.FormRequest(postpath, formdata=FormData, encoding='big5')

        ## department based finder(there are some special category will be ignored in college finder)
        elem = soup.find_all('select')[1].select("optgroup[label='其它']")[0]
        deptList = []
        for dept in elem.find_all('option'):
            print(dept.text)
            deptList.append(dept['value'])

        for dept in deptList:
            FormData = {
            'qdept': dept,
            'qYear':'106',
            'qTerm':'1',
            'seq1':'A',
            'seq2':'M'
            }
            
            yield scrapy.FormRequest(postpath, formdata=FormData, encoding='big5')


    def parse(self, response):
        soup = BeautifulSoup(response.body, 'lxml')
        table = soup.find('table')
        df_course = pd.read_html(str(table))[0]
        
        # duplicate rows having more than one for_depts and obligatory_tf
        del_row_idxs = []
        add_rows = []
        def duplicateDepts(row):
            if not '通' in row['必選修別']:
                forDepts = row['應修系級'].split()
                obligatory_tfs = row['必選修別'].split()

                if len(forDepts) > 1:
                    del_row_idxs.append(row.name)

                    for i in range(0, len(forDepts)):
                        row['應修系級'] = forDepts[i]
                        row['必選修別'] = obligatory_tfs[i]
                        add_rows.append(dict(row))

        df_course.apply(duplicateDepts,axis=1)
        
        # print('preprocess len = ', len(df_course))
        add_df = pd.DataFrame(add_rows)
        df_course = pd.concat([df_course, add_df])
        df_course.drop(del_row_idxs, inplace=True)
        # print('processed len = ', len(df_course))

        # match columns
        for row in df_course.iterrows():
            print(type(row))
            # 1.replace pd.null by None 2. transfer to str type
            def preprocess(item):
                if pd.isnull(item):
                    return None
                else:
                    return str(item)
            row = pd.Series(row[1]).apply(preprocess)
            
            courseItem = UcrawlerItem()
            ## department, obligatory_tf
            courseItem['department'] = row['開課系所'] if row['開課系所'] != None else None
            courseItem['obligatory_tf'] = True if row['必選修別'] == '必' else False

            ## for_dept, grade
            if not '通' in row['必選修別']:
                for_dept = re.sub("\d", "",  row['應修系級']) if row['應修系級'] != None else None
                grade = row['應修系級'].replace(for_dept, "") if row['應修系級'] != None else None
            else:
                for_dept = ", ".join(row['應修系級'].split()) if row['應修系級'] != None else None
                grade = None

            courseItem['for_dept'] = for_dept
            courseItem['grade'] = grade
            
            ## title, note
            if '備註' in row['科目名稱']:
                title = row['科目名稱'].split("備註")[0]
                note = row['科目名稱'].split("備註")[1].replace("：","")
                if note == "":
                    note = None 
            else:  ##basically, this will not happen
                title = row['科目名稱']
                note = None

            courseItem['title'] = title
            courseItem['note'] = note

            ## professor
            if row['授課教師'] != None:
                row['授課教師'] = row['授課教師'].replace("張�睇�","張恒豪").replace("林�琝�","林恒志")
                profs = list(row['授課教師'].split())
            else:
                profs = []

            ##deal with error code
            #if '�'.encode() in str(row['授課教師']).encode():
            #    print(row[['科目名稱','授課教師']])
            courseItem['professor'] = profs

            ## time, location
            if row['上課時間、教室'] != None:
                Ctime, location = self.parse_timeAndLocation(row['上課時間、教室'])
            else:
                Ctime = None
                location = None
            courseItem['time'] = Ctime
            courseItem['location'] = location

            ## credits
            courseItem['credits'] = float(row['學分']) if row['學分'] != None else None

            ## code, campus
            courseItem['code'] = row['課程流水號'] if row['課程流水號'] != None else None
            courseItem['campus'] = 'NTPU'
            courseItem['category'] = self.parse_catgory(courseItem['for_dept'], courseItem['obligatory_tf'])
            
            yield courseItem


    @staticmethod
    def parse_timeAndLocation(TimeAndLocation):
        if len(TimeAndLocation.replace('\t', ' ').split()) >= 1:
            timeAndClassroom = TimeAndLocation.replace('\t', ' ')
            items = timeAndClassroom.split()

            timeDist = []
            locationLi = []
            for item in items:
                if '週一' in item or '週二' in item or '週三' in item or '週四' in item or '週五' in item or '週六' in item or '週日' in item:
                    timeObj = {}
                    if '週一' in item:
                        timeObj['day'] = 1
                    elif '週二' in item:
                        timeObj['day'] = 2
                    elif '週三' in item:
                        timeObj['day'] = 3
                    elif '週四' in item:
                        timeObj['day'] = 4
                    elif '週五' in item:
                        timeObj['day'] = 5
                    elif '週六' in item:
                        timeObj['day'] = 6
                    elif '週日' in item:
                        timeObj['day'] = 7
    #                 re_words = re.compile(u"[\u4e00-\u9fa5]+") 
                    re_words = re.compile(u"[\d]+") 
                    res = list(pd.Series(re.findall(re_words, item)).apply(lambda x : int(x)))
                    timeObj['time'] = [i for i in range(res[0],res[1]+1)]
                    timeDist.append(timeObj)
                else:
                    if not '維護' in item:
                        locationLi.append(item)
            Ctime = timeDist if timeDist != [] else None 
            location = locationLi if locationLi != [] else None
        else:
            Ctime = None
            location = None

        return Ctime, location


    @staticmethod
    def parse_catgory(for_dept, obligatory_tf):  ##應修系級
        if "體育" in for_dept:
            return "體育類"
        elif "通識" in for_dept:
            return "通識類"
        elif "共同" in for_dept or "軍訓" in for_dept:
            return "其他類"
        else:
            return "必修類" if obligatory_tf else "選修類"
