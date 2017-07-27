# CampassCrawler (大學課程爬蟲)[![Build Status](https://travis-ci.org/Stufinite/CampassCrawler.svg?branch=master)](https://travis-ci.org/Stufinite/CampassCrawler)

## [爬蟲爬取清單](https://docs.google.com/spreadsheets/d/1shRsbpbYUQtol0Q1Gbgdd3xn4dQy0MHkqDfLIUlKPIQ/edit#gid=270187308)

## 執行指令:

1. 中科:`scrapy crawl NUTC -o NUTC.json -t json`
2. 中山:`scrapy crawl NSYSU -o NSYSU.json -t json`

## Getting Started

### Prerequisities

1. OS：Ubuntu / OSX would be nice
2. environment：need python3
  * Linux：`sudo apt-get update; sudo apt-get install; python3 python3-dev`
  * OSX：`brew install python3`

### Installing

1. 使用虛擬環境：
  1. 創建一個虛擬環境：`virtualenv venv`
  2. 啟動方法
     1. for Linux：`. venv/bin/activate`
     2. for Windows：`venv\Scripts\activate`
2. `pip install -r requirements.txt`

### Schema
1. 需要欄位：
    ```
    department （開課系所）
  	for_dept (上課系所)
  	grade （年級）
  	title_parsed （課名）
  	time （上課時間）
  	credits (學分)
  	obligatory_tf （必修或選修）
  	professor （教授）
  	location （上課地點）
  	code （課程id）
  	note (備註)
  	campus （校區）
    ```
2. 爬蟲輸出 JSON 格式：  

    ```
    {
      "title": "審計學 (學年)",
      "grade": "三１",
      "code": "D16049",
      "obligatory_tf": true,
      "location": [
        "(---)"
      ],
      "time": [
        {
          "day": 4,
          "time": [
            5,
            6,
            7
          ]
        }
      ],
      "professor": "劉若蘭",
      "department": "會資",
      "credits": 3.0,
      "note": "---",
      "campus": "NUTC",
      "for_dept": "會資"
    }
    ```
3. 例外：
  1. 欄位為空值：統一填 `None`

## Built With

* python3.5

## Contributors

* **邱冠喻** - *Initial work* - [Pastleo](https://github.com/chgu82837)
* **戴均民** - *Initial work* - [taichunmin](https://github.com/taichunmin)
* **黃川哲** - *Initial work* - [CJHwong](https://github.com/CJHwong)
* **張泰瑋** [david](https://github.com/david30907d)

## Acknowledgments

* 感謝中興大學計資中心提供協助
* 感謝[黃川哲](https://github.com/CJHwong)大大開的坑，讓學弟學了不少的Python，學長們的 code 也讓我受益良多~
* 感謝[Pastleo](https://github.com/chgu82837)大大開的坑，讓學弟學了不少的Python，學長們的 code 也讓我受益良多~

## License

This project is licensed under the **GNU 3.0** License - see the [LICENSE.md](LICENSE.md) file for details
