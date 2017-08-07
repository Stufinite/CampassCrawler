from selenium import webdriver
import platform, os

def cross_selenium(chrome=False):
	sysName = platform.system()
	if sysName == "Windows":
		if chrome:
			driver = webdriver.Chrome(executable_path=os.path.join('.', 'chromedriver.exe'))
		else:
			driver = webdriver.PhantomJS(executable_path=os.path.join('.', 'phantomjs.exe'))

	else:
		if chrome:
			driver = webdriver.Chrome(executable_path=os.path.join('.', 'chromedriver'))
		else:
			# driver = webdriver.PhantomJS(executable_path=os.path.join('.', 'phantomjs'))
			driver = webdriver.PhantomJS()
	return driver 

