import unittest, subprocess, json, sys

class UCrawlerTest(unittest.TestCase):
	def test_spider(self):
		status = True
		with open('scrapy.log', 'r', encoding='UTF-8') as f:
			file = f.readlines()
			for index, i in enumerate(file):
				if 'Traceback' in i:
					status = False
					for p in range(index, index+20):
						print(file[p], end='')
					break
		self.assertEqual(True, status)

if __name__ == '__main__':
	subprocess.call(['scrapy', 'crawl', sys.argv.pop(), '--logfile', 'scrapy.log'])
	unittest.main()