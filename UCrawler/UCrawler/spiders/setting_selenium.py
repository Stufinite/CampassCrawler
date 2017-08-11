from selenium import webdriver
import platform, os
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

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
			driver = webdriver.PhantomJS(executable_path=os.path.join('.', 'phantomjs'), service_args=['--ignore-ssl-errors=true', '--ssl-protocol=any'])
	return driver 


def tryLocateElemById(driver ,Id, timeout = 10):
    element = WebDriverWait(driver, timeout).until(
        EC.presence_of_element_located((By.ID, Id))
    )
    return element

def tryLocateElemByXpath(driver ,Xpath, timeout = 10):
    element = WebDriverWait(driver, timeout).until(
        EC.presence_of_element_located((By.XPATH, Xpath))
    )
    return element

def tryLocateElemBySelector(driver ,selector, timeout = 10):
    element = WebDriverWait(driver, timeout).until(
        EC.presence_of_element_located((By.CSS_SELECTOR, selector))
    )
    return element
    	

