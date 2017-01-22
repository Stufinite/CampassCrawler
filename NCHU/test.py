#!/usr/bin/env python3
import json
try:
	with open('json/U.json', 'r', encoding='UTF-8') as f:
	    json.load(f)
	with open('json/G.json', 'r', encoding='UTF-8') as f:
	    json.load(f)
	with open('json/D.json', 'r', encoding='UTF-8') as f:
	    json.load(f)
	with open('json/N.json', 'r', encoding='UTF-8') as f:
	    json.load(f)
	with open('json/O.json', 'r', encoding='UTF-8') as f:
	    json.load(f)
	with open('json/W.json', 'r', encoding='UTF-8') as f:
	    json.load(f)
	print('success')
except Exception as e:
	raise e