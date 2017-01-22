#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from crawler import Crawler
from import2DB import import2Mongo
import time
if __name__ == "__main__":
	while True:		
		c = Crawler()
		c.start()
		i = import2Mongo()
		i.save2DB()
		time.sleep(1800)