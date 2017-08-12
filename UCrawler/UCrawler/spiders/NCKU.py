import requests
from bs4 import BeautifulSoup
import re
import scrapy
import pandas as pd
from UCrawler.items import UcrawlerItem


class NtuSpider(scrapy.Spider):
    name = 'NCKU'
    allowed_domains = ['course-query.acad.ncku.edu.tw']
    start_urls = ['http://course-query.acad.ncku.edu.tw/qry/', 
                  'http://course-query.acad.ncku.edu.tw/qry/index.php?lang=zh_tw']
    headers = {'user-agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36','referer':'http://www.ntpu.edu.tw/chinese/'}

    def start_requests(self):
        path = self.start_urls[1]     
        res = requests.get(path)
        res.encoding = res.apparent_encoding
        html_doc = res.text
        soup = BeautifulSoup(html_doc, 'lxml')

        for a in soup.find_all('a'):
            if "qry001.php" in a['href']:
                url = self.start_urls[0] + str(a['href']) + "&lang=zh_tw"
                yield scrapy.Request(url=url, headers=self.headers, callback=self.parse)

        # url = self.start_urls[0] + "qry001.php?dept_no=A2" + "&lang=zh_tw"
        # yield scrapy.Request(url=url, headers=self.headers, callback=self.parse)


    def parse(self, response):
        df_course = pd.read_html(response.body)[0]
        columns = []
        for column in df_course.columns:
            columns.append(column.replace("*:主負責老師", "").replace("(連結課程地圖)", "").replace(" ", ""))
        df_course.columns = columns

        for row in df_course.iterrows():
            def preprocess(item):
                if pd.isnull(item):
                    return None
                else:
                    return str(item)
            row = pd.Series(row[1]).apply(preprocess)

            if row['備註'] != '備註':
                # file.write(row)
                # match columns
                courseItem = UcrawlerItem()
                courseItem['department'] = row['系所名稱'] if row['系所名稱'] != None else None
                courseItem['for_dept'] =  row['系所名稱'] if row['系所名稱'] != None else None
                courseItem['obligatory_tf'] = True if row['選必修'] == '必修' else False
                courseItem['grade'] = row['年級'] if row['年級'] != None else None

                courseItem['title'] = row['課程名稱'] if row['課程名稱'] != None else None
                courseItem['note'] =  row['備註'] if row['備註'] != None else None
                courseItem['professor'] = self.parse_teacher(row['教師姓名'])

                Ctime = self.parse_time(row['時間'])
                courseItem['time'] = Ctime
                courseItem['location'] = list(set(row['教室'].split())) if row['教室'] != None else None

                courseItem['credits'] = float(row['學分']) if row['學分'] != None else None
                courseItem['code'] = row['課程碼'] if row['課程碼'] != None else None
                courseItem['campus'] = 'NCKU'
                courseItem['category'] = self.parse_category(row['系號'], courseItem['obligatory_tf'])
                yield courseItem

    @staticmethod
    def parse_teacher(teacher):
        teacherLi = []
        if teacher != None:
            teacher = teacher.replace("　", " ")
            teacherLi.extend(re.findall(r"[\u4e00-\u9fa5]{2,4}[*]{1}", teacher))
            teacherLi.extend(re.findall(r"[\u4e00-\u9fa5]{1}[ ]{1}[\u4e00-\u9fa5]{1}[*]{1}", teacher))

            for t in teacherLi:
                teacher = teacher.replace(t, "")
            
            teacherLi.extend(re.findall(r"[\u4e00-\u9fa5]{2,4}", teacher))
            teacherLi.extend(re.findall(r"[\u4e00-\u9fa5]{1}[ ]{1}[\u4e00-\u9fa5]{1}", teacher))
        else:
            teacherLi = None

        return teacherLi

    @staticmethod
    def parse_time(ctime):
        processedTimeLi = []
        if ctime == None or ctime == "未定":
            processedTimeLi = None
        else:
            timeLi = []
            timeLi.extend(re.findall(r'\[\d\]\d{1}~{1}[\d]{1}', ctime))
            timeLi.extend(re.findall(r'\[\d\]\d{1}', ctime))
            timeLi.extend(re.findall(r'\[\d\]N', ctime))
            for originalTimeObj in timeLi:
                processedTimeObj = {}
                daypart = re.findall(r'\[\d\]', originalTimeObj)[0]
                day = int(daypart.replace("[", "").replace("]", ""))
                processedTimeObj['day'] = day
                timepart = originalTimeObj.replace(daypart, "")
                if len(timepart.split("~")) == 1:
                    if timepart != 'N':
                        processedTimeObj['time'] = [int(timepart)]
                    else:
                        processedTimeObj['time'] = [timepart]

                else:
                    start = int(timepart.split("~")[0])
                    end = int(timepart.split("~")[1])
                    processedTimeObj['time'] = list(range(start, end+1))

                processedTimeLi.append(processedTimeObj)
        return processedTimeLi


    @staticmethod
    def parse_category(departmentNum, obligatory_tf):
        if departmentNum == "A2":
            return "體育類"
        elif departmentNum == "A9":
            return "通識類"
        elif departmentNum in ['A3','A4','A5','A6','AA','AH','AN','C0','A1','AG','A7']:
            return "其他類"
        else:
            return "必修類" if obligatory_tf else "選修類"



