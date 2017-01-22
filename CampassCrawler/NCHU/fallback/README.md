# NCHU-python-Crawler (中興大學課程爬蟲)[![Build Status](https://travis-ci.org/NCHUSG/Python-Crawler.svg?branch=master)](https://travis-ci.org/NCHUSG/Python-Crawler)

由於中興大學沒有課程的 open data, 所以便製作 Python 爬蟲將教務處的課程資料轉換成 json

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisities

```
sudo apt-get update
sudo apt-get install python3 python3-dev
```

### Installing

```
git clone git@github.com:NCHUSG/Python-Crawler.git
pip3 install -r requirements.txt
```

## Deployment

1. Change your directory to this project

  * `cd /path/to/project/fallback`

2. Use Crontab to make crawler automatically run in background

	* `crontab -e`

3. Paste the command below into the bottom of the crontab file :

	* 學士班 ( Undergraduate )`* * * * * python3 required.py https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_home U fileName.json  [ C10 | C20 C30 U11 U12 U13 U21 U23 U24 U28 U29 U30F U30G U30H U31 U32 U33A U33B U34 U35 U36 U37 U38B U38A U39 U40 U42 U43 U44 U51 U52 U53B U53A U54A U54B U56 U61B U61A U62A U62B U63 U64A U64B U65 U66 ]`

	* 碩班 ( Graduate )`* * * * *python required.py https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_home G fileName.json B20 B60 G11 G12 G13 G14 G15 G17 G18 G19 G21 G22 G23 G24 G26 G261 G28 G29 G30F G30G G30I G31 G32 G33 G34 G35 G36 G37 G38 G39 G40 G41 G42 G43 G44 G45 G46 G47 G49 G51 G52 G53 G531 G54 G541 G55 G56 G58 G59 G61 G62 G63 G64 G65 G66 G67 G68 G81 G82 G91 G93 G94`

	* 夜間部 ( Night School )`* * * * *python required.py https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_home N fileName.json C10 C20 C30 N00 N01F N01G N11 N12 N46 N79`

	* 體育課 ( parse PE class )`* * * * * python3 PE.py https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_all fileName.json [ 1 | 7 B 4 0 H ]`

	* 通識課 ( for General Edu class )`* * * * * python3 general_EDU.py https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_gene fileName.json [ E | F G 3 8]`

### Result
輸出 JSON 格式

    {
      "course": [
        {
          "class": "1",
          "code": "1032",
          "credits": "2",
          "credits_parsed": 2,
          "department": "環境工程學系學士班",
          "discipline": "",
          "enrolled_num": "0",
          "for_dept": "環境工程學系學士班",
          "hours": "2",
          "hours_parsed": "2",
          "intern_location": [
            ""
          ],
          "intern_time": "",
          "language": "中文",
          "location": [
            "C405"
          ],
          "note": "",
          "number": "52",
          "number_parsed": 52,
          "obligatory": "選修",
          "obligatory_tf": false,
          "prerequisite": "",
          "professor": "望熙榮",
          "time": "412",
          "time_parsed": [
            {
              "day": 4,
              "time": [
                1,
                2
              ]
            }
          ],
          "title": "R程式在環工之應用 `Application of R Program on Environmental Engineering",
          "title_parsed": {
            "en_US": "Application of R Program on Environmental Engineering",
            "zh_TW": "R程式在環工之應用"
          },
          "url": "1415",
          "year": "半"
        },
        ...
      ]
    }

## Built With

* python3.4

## Versioning

For the versions available, see the [tags on this repository](https://github.com/NCHUSG/Python-Crawler/tags). 

## Contributors

* **邱冠喻** - *Initial work* - [Pastleo](https://github.com/chgu82837)
* **戴均民** - *Initial work* - [taichunmin](https://github.com/taichunmin)
* **黃川哲** - *Initial work* - [CJHwong](https://github.com/CJHwong)
* **張泰瑋** [david](https://github.com/david30907d)

## License

This project is licensed under the **GNU 3.0** License - see the [LICENSE.md](../LICENSE.md) file for details

## Acknowledgments

* 感謝[Pastleo](https://github.com/chgu82837)大大開的坑，讓學弟學了不少的Python，學長們的 code 也讓我受益良多~