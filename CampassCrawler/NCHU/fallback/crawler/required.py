#!/usr/bin/env python3
import json,re,sys,pyprind,requests,urllib,traceback
from pyquery import PyQuery as pq

head_start_value = ["必選別"]
row_start_value = ["必修","選修"]
col_namekey = {
    "※上課時間":"time",
    "上課教室":"location",
    "上課教師":"professor",
    "上課時數":"hours",
    "備註":"note",
    "先修科目":"previous",
    "全/半年":"year",
    "學分數":"credits",
    "實習教室":"intern_location",
    "實習教師":"professor",
    "實習時數":"hours",
    "實習時間":"intern_time",
    "必選別":'obligatory',
    "科目名稱":"title",
    "語言":"language",
    "選課號碼":"code",
    "開課人數":"number",
    "開課單位":"department",
    "for_dept":"for_dept",
    "class":"class",
}
obligatorytf = {
    "必修":True,
    "選修":False
}
required_key = {"obligatory","code","title","department","credits","professor"}
int_field = ["number","hours","credits"]

def get_nchu_course(url, payload):
    response = requests.post(url, data=payload)
    datas = []
    for table in re.findall(r'<TABLE.*?</TABLE>', response.text, re.S):#re:正規表示法，findallc會回傳所有不重疊的搜尋結果
        #r表示裡面放的是正規表示法，第二個參數放的是字串，re.S表示flag，他讓.的定義也包含了'\n'
        data = {}
        table = table.replace("</BR>","`").replace("\u3000",'').replace(",",'`').replace("</br>","`")#取代字串，\u3000是全形空白
        # with open('debug.html', 'w') as fdebug:
        #     fdebug.write(table)
        d = pq('<div>'+table+'</div>')#PyQuery的建構式就是可以直接接受一個xml的是串或是html檔
        table_title = d('strong:contains("系所名稱")').text()#d就是jQuery的$
        if table_title == '':
            continue
        match = re.fullmatch(r'系所名稱:(.*?) 年級:(.*?) 班別:(.*?)', table_title)        
        #如果string參數有完全符符合pattern的話就會回傳，否則為none
        data['for_dept'], data['class'] = match.group(1), match.group(2)+match.group(3)
        #fullmatch回傳型態為tuple，group就跟index一樣
        #而且data為字典，所以可以直接增加key
        thead = []#這一行就是table第一行TR，標示課名、時間、開課單位等等
        for tr in d('tr'):
            row = [ str(pq(i).text().strip()) for i in pq(tr).find('td') ]#for迴圈的簡潔寫法，直接把i存入list           
            #pq(tr)是所有tr的集合，取道i時還是要加$(i)，也就是d(i) or pq(i)
            if len(thead) == 0:
                thead = row#這樣就可以把第一行存進thead裡面，以後就不會再去修改到他了
            else:
                row = dict(zip(thead, row))#用thead當dict的key
                row.update(data)#update是將另一個dict合併進來的方法，data裡面存系所資料，在通識課裡用不到
                datas.append(row)
    return datas

def parse_time(t_str):
    # print(t_str)
    result=[]  
    return [{"day":int(d[0]),"time":[int(h,16) for h in list(d[1:]) if h in "123456789ABCD" ]} for d in t_str.split("`") if (len(d) and d[0] in "1234567")]
    #for i in t_str.split(","):        
    #   if len(i) and i[0] in '1234567':

    #第一個if是為了要篩選掉長度為零的字串，以及不在星期一到星期天的時間，若有兩天，會分兩次回傳字串
    #第二層迴圈在前面的dict裡面，接受字串，取從1到最後一位的字元
    #判斷為合法的結束後，用16進制將其轉成int
    #而day的資料並不在第二層迴圈內，會直接填入

def parse_title(t_str):
    title_splited = [i.strip() for i in t_str.split('`')]
    if len(title_splited) == 1:
        return {'zh_TW': title_splited[0]}
    else:
        return {'zh_TW': title_splited[0], 'en_US': title_splited[1]}
    raise Exception('parse_title error: '+t_str)

def parse_location(location_str):
#傳進來的地點字串，若有兩個應該會是
#S201`S202，所以就用split("`")把他切開
    return location_str.split("`")

def parse(data):#會傳入一門課程的dict
    r_data = {}    
    for k in data.keys():#用list回傳dict裡面所有的key
        if k in col_namekey:
            col_key = col_namekey[k]#將中文的key轉成英文的
            if col_key not in r_data or len(data[k]) > len(r_data[col_key]):
                #不懂為什麼要判斷長度?????????????????????????????????????????????????????????????????????
                r_data[col_key] = data[k]
            if col_key == "obligatory":
                r_data["obligatory_tf"] = obligatorytf[r_data[col_key]]
                #新增obligatory_tf這個key
            elif col_key == "time" or col_key == "intern_time":
                time_object = parse_time(r_data[col_key])
                #time_object的型態為list，然後裡面放dict
                if("time_parsed" not in r_data):
                    #新增time_parsed這個key
                    r_data["time_parsed"] = []#這是為了要能夠使用extend這個方法，才要先建立這個key               
                r_data["time_parsed"].extend(time_object)
            elif col_key == "title":
                r_data['title_parsed'] = parse_title(r_data[col_key])
                #同上
            elif col_key == "location" or col_key == "intern_location":
                r_data[col_key] = parse_location(r_data[col_key])
            elif col_key in int_field:
                r_data[col_key + "_parsed"] = int(r_data[col_key]) if len(r_data[col_key]) else 0
                #如果有東西len()必不為0，將其轉成int
    for k in required_key:
        if len(r_data.get(k, '')) == 0:
            #如果沒有這個key，則''的len就會是0
            raise Exception(k+' is required in '+str(r_data))    
                
    return r_data

if __name__ == "__main__":
    if len(sys.argv) < 3:
        #sys.argv[0]是模組名稱喔!
        print("Usage:\n\tpython[3] "+sys.argv[0]+" <url> <degree> <json_output> dept_id1 [dept_id2 [dept_id3 ...]]")
        print("\n\n\t URL can be:https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_home");
        print("\t URL can be:https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_gene");
        sys.exit(1)#0為正常結束，其他數字exit會拋出一個例外，可以被捕獲

    url = sys.argv[1] 
    degree = sys.argv[2]
    jfile = sys.argv[3]           
    dept_id = sys.argv[4:]
    err = []
    print(dept_id)
    my_prbar = pyprind.ProgBar(len(dept_id),title = "共 %d 個系要處理" % len(dept_id))
    #建立一個進度條物件
    notFirst1 = False
    try:
        notFirst1 = True
        notFirst2 = False

        for ID in dept_id:
            raw = get_nchu_course(url,{'v_career':degree,'v_dept': ID})
            data = []

            for r in raw:
                try:
                    data.append(parse(r))
                except Exception as e:
                    err.append([r,str(e)+traceback.format_exc()])
                    #traceback這個module可以追蹤是哪一行造成exception
                    #traceback.format_exc()的型態是字串型態，所以只有e要轉成str
                    #append裡面放的是一個list，用，格該並不是額外的參數
                    #就單單只是list裡面有兩個物件，最後格式就會變成課程資料+'，'+error
            # print(data)
            with open(jfile, 'w', encoding='UTF-8') as f:
                json.dump({'course':data}, f)
            notFirst2 = True
            my_prbar.update(1,item_id = ID)#item_id可以讓使用者追蹤到底執行到第幾個ID
            #ID通常是放for loop裏面的變數，update()會讓進度條更新

    except Exception as e:
        print("================ ERR ================")
        print(e)
        print(traceback.format_exc())

    print("================ WARN ================")
    with open("err.txt", 'w' ,encoding='UTF-8') as error_file:
        error_file.write(str(err))