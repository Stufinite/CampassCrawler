install:
	pip install -r requirements.txt

test:
	python ./crawler.py
	python ./fallback/crawler/required.py https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_home U fileName.json C10 C20 C30 U11 U12 U13 U21 U23 U24 U28 U29 U30F U30G U30H U31 U32 U33A U33B U34 U35 U36 U37 U38B U38A U39 U40 U42 U43 U44 U51 U52 U53B U53A U54A U54B U56 U61B U61A U62A U62B U63 U64A U64B U65 U66
	python ./fallback/crawler/required.py https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_home G fileName.json B20 B60 G11 G12 G13 G14 G15 G17 G18 G19 G21 G22 G23 G24 G26 G261 G28 G29 G30F G30G G30I G31 G32 G33 G34 G35 G36 G37 G38 G39 G40 G41 G42 G43 G44 G45 G46 G47 G49 G51 G52 G53 G531 G54 G541 G55 G56 G58 G59 G61 G62 G63 G64 G65 G66 G67 G68 G81 G82 G91 G93 G94
	python ./fallback/crawler/required.py https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_home N fileName.json C10 C20 C30 N00 N01F N01G N11 N12 N46 N79
	python ./fallback/crawler/PE.py https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_all fileName.json 1 7 B 4 0 H 
	python ./fallback/crawler/general_EDU.py https://onepiece.nchu.edu.tw/cofsys/plsql/crseqry_gene fileName.json E F G 3 8
	python ./test.py

clean:
	rm -f *.json
	rm -rf err.txt debug.html venv
	rm ./fallback/crawler/err.txt ./fallback/crawler/debug.html