# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

import scrapy


class UcrawlerItem(scrapy.Item):
    # define the fields for your item here like:
	department = scrapy.Field()
	for_dept = scrapy.Field()
	grade = scrapy.Field()
	title_parsed = scrapy.Field()
	time = scrapy.Field()
	credits = scrapy.Field()
	obligatory_tf = scrapy.Field()
	professor = scrapy.Field()
	location = scrapy.Field()
	code = scrapy.Field()
	note = scrapy.Field()