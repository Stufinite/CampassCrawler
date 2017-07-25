import unittest, subprocess, json

class NUTCTest(unittest.TestCase):
	def setUp(self):
		self.json = json.load(open('NUTC.json', 'r'))

	def test_1(self):
		actual = [i for i in self.json if i['code']=='D18976'][0]

		self.assertEqual('心理學與自我成長 (社會科學領域)', actual['title'])
		self.assertEqual('D18976', actual['code'])
		self.assertEqual([{"day": 4,"time": [3,4]}], actual['time'])
		self.assertEqual('二４', actual['grade'])
		self.assertEqual('劉家佑', actual['professor'])
		self.assertEqual('通識', actual['for_dept'])
		self.assertEqual('通識', actual['department'])

	def test_2(self):
		actual = [i for i in self.json if i['code']=='D19019'][0]

		self.assertEqual('衛星導航科技 (自然科學領域)', actual['title'])
		self.assertEqual('D19019', actual['code'])
		self.assertEqual([{"day": 2,"time": [5,6]}], actual['time'])
		self.assertEqual('三Ｂ', actual['grade'])
		self.assertEqual('涂裕民', actual['professor'])
		self.assertEqual('通識', actual['for_dept'])
		self.assertEqual('通識', actual['department'])

	def test_3(self):
		actual = [i for i in self.json if i['code']=='D23277'][0]

		self.assertEqual('英語聽力與閱讀（一）', actual['title'])
		self.assertEqual('D23277', actual['code'])
		self.assertEqual([{"day": 5,"time": [5,6]}], actual['time'])
		self.assertEqual('二２', actual['grade'])
		self.assertEqual('宋思煌', actual['professor'])
		self.assertEqual('語言', actual['for_dept'])
		self.assertEqual('語言', actual['department'])

	def test_4(self):
		actual = [i for i in self.json if i['code']=='D17442'][0]

		self.assertEqual('英語口語表達（三） (學年)', actual['title'])
		self.assertEqual('D17442', actual['code'])
		self.assertEqual([{"day": 3,"time": [1,2]}], actual['time'])
		self.assertEqual('五甲', actual['grade'])
		self.assertEqual('蔡嬌燕', actual['professor'])
		self.assertEqual('日語', actual['for_dept'])
		self.assertEqual('日語', actual['department'])

if __name__ == '__main__':
	unittest.main()