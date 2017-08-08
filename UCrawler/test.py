import unittest, subprocess, json

class UCrawlerTest(unittest.TestCase):
	def setUp(self):
		pass
	def test_spider(self):
		status = True
		with open('scrapy.log', 'r', encoding='UTF-8') as f:
			for i in f:
				if 'fail' in i:
					status = False
					break
		self.assertEqual(True, status)

if __name__ == '__main__':
	unittest.main()