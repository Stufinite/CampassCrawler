require 'crawler_rocks'
require 'pry'
require 'iconv'
require 'json'


class TmuCourseCrawler
	def initialize year: nil, term: nil, update_progress: nil, after_each: nil
		@year = year
    	@term = term
		@post_url = "http://acadsys.tmu.edu.tw/pubinfo/cousreSearch.aspx"
		@update_progress_proc = update_progress
        @after_each_proc = after_each
	end

	def courses 
		@courses = []
		year = @year
		term = @term

		1.upto(250) do |page|
			begin
			r = `curl "http://acadsys.tmu.edu.tw/pubinfo/cousreSearch.aspx" -H "Cookie: ASPSESSIONIDASDTBDTC=HDFLMMGCPAIPEMPKAMDKMGFH; ASPSESSIONIDASDSCBTD=JANFGGICLADOCKIINJAJCALF" -H "Origin: http://acadsys.tmu.edu.tw" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-TW,zh;q=0.8,en-US;q=0.6,en;q=0.4" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.155 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: http://acadsys.tmu.edu.tw/pubinfo/cousreSearch.aspx" -H "Connection: keep-alive" --data "__EVENTTARGET=ctl00"%"24ContentPlaceHolder1"%"24GridView1&__EVENTARGUMENT=Page"%"24#{page}&__LASTFOCUS=&__VIEWSTATE="%"2FwEPDwUJMTc0NzU3NTA2D2QWAmYPZBYCAgMPZBYQAgcPDxYCHgRUZXh0BRLnm67liY3miYDlnKjkvY3nva5kZAIJDw8WAh8ABRLoqrLnqIvlv6vpgJ"%"2Fmn6XoqaJkZAILDw8WAh8ABRLoqrLnqIvlv6vpgJ"%"2Fmn6XoqaJkZAINDw8WAh8ABRLns7vmiYDoqrLnqIvmn6XoqaJkZAIPDw8WAh8ABRXlhajoi7Hoqp7oqrLnqIvmn6XoqaJkZAIRD2QWEgIBDw8WAh8ABQblrbjmnJ9kZAIDDxAPFgYeDURhdGFUZXh0RmllbGQFBHRleHQeDkRhdGFWYWx1ZUZpZWxkBQV2YWx1ZR4LXyFEYXRhQm91bmRnZBAVHwQxMDQxBDEwMzIEMTAzMQQxMDIyBDEwMjEEMTAxMgQxMDExBDEwMDIEMTAwMQQwOTkyBDA5OTEEMDk4MgQwOTgxBDA5NzIEMDk3MQQwOTYyBDA5NjEEMDk1MgQwOTUxBDA5NDIEMDk0MQQwOTMyBDA5MzEEMDkyMgQwOTIxBDA5MTIEMDkxMQQwOTAyBDA5MDEEMDg5MgQwODkxFR8EMTA0MQQxMDMyBDEwMzEEMTAyMgQxMDIxBDEwMTIEMTAxMQQxMDAyBDEwMDEEMDk5MgQwOTkxBDA5ODIEMDk4MQQwOTcyBDA5NzEEMDk2MgQwOTYxBDA5NTIEMDk1MQQwOTQyBDA5NDEEMDkzMgQwOTMxBDA5MjIEMDkyMQQwOTEyBDA5MTEEMDkwMgQwOTAxBDA4OTIEMDg5MRQrAx9nZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZGQCBQ8PFgIfAAUV6KuL6YG45Y"%"2BW5p"%"2Bl6Kmi5pa55byPZGQCBw8QDxYGHwEFBXZhbHVlHwIFBG5hbWUfA2dkEBUDDOiqsueoi"%"2BWQjeeosQzmlZnluKvlp5PlkI0G6Kqy6JmfFQMKY291cnNlTmFtZQt0ZWFjaGVyTmFtZQhjb3Vyc2VJRBQrAwNnZ2dkZAIJDw8WAh8ABRLoq4vovLjlhaXpl5zpjbXlrZdkZAIMD2QWLAIBDw8WAh8ABQzplovoqrLmmYLplpNkZAIFDw8WAh8ABQbkuI3pmZBkZAIJDw8WAh8ABQbpmZDlrppkZAILDxAPFgIeB0NoZWNrZWRoZGRkZAIMDw8WAh8ABQnmmJ"%"2FmnJ"%"2FkuIBkZAIODxAPFgIfBGhkZGRkAg8PDxYCHwAFCeaYn"%"2Bacn"%"2BS6jGRkAhEPEA8WAh8EaGRkZGQCEg8PFgIfAAUJ5pif5pyf5LiJZGQCFA8QDxYCHwRoZGRkZAIVDw8WAh8ABQnmmJ"%"2FmnJ"%"2Flm5tkZAIXDxAPFgIfBGhkZGRkAhgPDxYCHwAFCeaYn"%"2Bacn"%"2BS6lGRkAhoPEA8WAh8EaGRkZGQCGw8PFgIfAAUJ5pif5pyf5YWtZGQCHQ8QDxYCHwRoZGRkZAIeDw8WAh8ABQnmmJ"%"2FmnJ"%"2Fml6VkZAIgDw8WAh8ABQznr4DmrKHvvJrnrKxkZAIiDxBkDxYNZgIBAgICAwIEAgUCBgIHAggCCQIKAgsCDBYNEAUBMQUBMWcQBQEyBQEyZxAFATMFATNnEAUBNAUBNGcQBQE1BQE1ZxAFATYFATZnEAUBNwUBN2cQBQE4BQE4ZxAFATkFATlnEAUCMTAFAjEwZxAFAjExBQIxMWcQBQIxMgUCMTJnEAUCMTMFAjEzZxYBZmQCIw8PFgIfAAUJ56"%"2BA6Iez56ysZGQCJQ8QZA8WDWYCAQICAgMCBAIFAgYCBwIIAgkCCgILAgwWDRAFATEFATFnEAUBMgUBMmcQBQEzBQEzZxAFATQFATRnEAUBNQUBNWcQBQE2BQE2ZxAFATcFATdnEAUBOAUBOGcQBQE5BQE5ZxAFAjEwBQIxMGcQBQIxMQUCMTFnEAUCMTIFAjEyZxAFAjEzBQIxM2cWAWZkAiYPDxYCHwAFA"%"2BevgGRkAg4PDxYCHwAFBuafpeipomRkAhAPDxYCHwAFH"%"2BS4i"%"2Bi8ieafpeipoue1kOaenOeCuiBFeGNlbCDmqpRkZAIUDzwrAA0CAA8WBB8DZx4LXyFJdGVtQ291bnQCjw1kDBQrABcWCB4ETmFtZQUG5a245pyfHgpJc1JlYWRPbmx5aB4EVHlwZRkrAh4JRGF0YUZpZWxkBQblrbjmnJ8WCB8GBQzplovoqrLlrbjpmaIfB2gfCBkrAh8JBQzplovoqrLlrbjpmaIWCB8GBQzplovoqrLns7vmiYAfB2gfCBkrAh8JBQzplovoqrLns7vmiYAWCB8GBQboqrLomZ8fB2gfCBkrAh8JBQboqrLomZ8WCB8GBQbnj63liKUfB2gfCBkrAh8JBQbnj63liKUWCB8GBQzoqrLnqIvlkI3nqLEfB2gfCBkrAh8JBQzoqrLnqIvlkI3nqLEWCB8GBQnpoJjln5"%"2FliKUfB2gfCBkrAh8JBQnpoJjln5"%"2FliKUWCB8GBQblubTntJofB2gfCBkrAh8JBQblubTntJoWCB8GBQblrbjliIYfB2gfCBkrAh8JBQblrbjliIYWCB8GBQzorJvmvJTmmYLmlbgfB2gfCBkpWFN5c3RlbS5CeXRlLCBtc2NvcmxpYiwgVmVyc2lvbj0yLjAuMC4wLCBDdWx0dXJlPW5ldXRyYWwsIFB1YmxpY0tleVRva2VuPWI3N2E1YzU2MTkzNGUwODkfCQUM6Kyb5ryU5pmC5pW4FggfBgUM5a"%"2Bm6amX5pmC5pW4HwdoHwgZKwIfCQUM5a"%"2Bm6amX5pmC5pW4FggfBgUK5YWoL"%"2BWNiuW5tB8HaB8IGSsCHwkFCuWFqC"%"2FljYrlubQWCB8GBQrpgbgv5b"%"2BF5L"%"2BuHwdoHwgZKwIfCQUK6YG4L"%"2BW"%"2FheS"%"2FrhYIHwYFDOaOiOiqsuaVmeW4qx8HaB8IGSsCHwkFDOaOiOiqsuaVmeW4qxYIHwYFBumAseS4gB8HaB8IGSsCHwkFBumAseS4gBYIHwYFBumAseS6jB8HaB8IGSsCHwkFBumAseS6jBYIHwYFBumAseS4iR8HaB8IGSsCHwkFBumAseS4iRYIHwYFBumAseWbmx8HaB8IGSsCHwkFBumAseWbmxYIHwYFBumAseS6lB8HaB8IGSsCHwkFBumAseS6lBYIHwYFBumAseWFrR8HaB8IGSsCHwkFBumAseWFrRYIHwYFBumAseaXpR8HaB8IGSsCHwkFBumAseaXpRYIHwYFDOaOiOiqsuWcsOm7nh8HaB8IGSsCHwkFDOaOiOiqsuWcsOm7nhYIHwYFBuWCmeioux8HaB8IGSsCHwkFBuWCmeiouxYCZg9kFhICAQ9kFi5mDw8WAh8ABQQxMDQxZGQCAQ8PFgIfAAU65Lq65paH5pqo56S"%"2B5pyD56eR5a246ZmiICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRkAgIPDxYCHwAFR"%"2BmGq"%"2BeZguaaqOeUn"%"2BeJqeenkeaKgOazleW"%"2Bi"%"2BeglOeptuaJgOeiqeWjq"%"2BePrSAgICAgICAgICAgICAgICAgICAgICAgICAgZGQCAw8PFgIfAAUJCjM0MDAwMDEwZGQCBA8PFgIfAAUGJm5ic3A7ZGQCBQ8PFgIfAAUP6KGb55Sf6KGM5pS"%"2F5rOVZGQCBg8PFgIfAAUGJm5ic3A7ZGQCBw8PFgIfAAUBMmRkAggPDxYCHwAFATJkZAIJDw8WAh8ABQEyZGQCCg8PFgIfAAUCICBkZAILDw8WAh8ABQPljYpkZAIMDw8WAh8ABQPpgbhkZAINDw8WAh8ABQnmooHlv5fps7RkZAIODw8WAh8ABQYmbmJzcDtkZAIPDw8WAh8ABQYmbmJzcDtkZAIQDw8WAh8ABQYmbmJzcDtkZAIRDw8WAh8ABQIzNGRkAhIPDxYCHwAFBiZuYnNwO2RkAhMPDxYCHwAFBiZuYnNwO2RkAhQPDxYCHwAFBiZuYnNwO2RkAhUPDxYCHwAFEumGq"%"2BaWh"%"2BaJgOiojuirluWupGRkAhYPDxYCHwAFBiZuYnNwO2RkAgIPZBYuZg8PFgIfAAUEMTA0MWRkAgEPDxYCHwAFOuS6uuaWh"%"2BaaqOekvuacg"%"2BenkeWtuOmZoiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZAICDw8WAh8ABUfphqvnmYLmmqjnlJ"%"2Fniannp5HmioDms5XlvovnoJTnqbbmiYDnoqnlo6vnj60gICAgICAgICAgICAgICAgICAgICAgICAgIGRkAgMPDxYCHwAFCQozNDAwMDAxMmRkAgQPDxYCHwAFBiZuYnNwO2RkAgUPDxYCHwAFIeeUn"%"2BmGq"%"2BeglOeptuWAq"%"2BeQhuiIh"%"2BazleW"%"2Bi"%"2BWwiOmhjGRkAgYPDxYCHwAFBiZuYnNwO2RkAgcPDxYCHwAFATJkZAIIDw8WAh8ABQEyZGQCCQ8PFgIfAAUBMmRkAgoPDxYCHwAFAiAgZGQCCw8PFgIfAAUD5Y2KZGQCDA8PFgIfAAUD6YG4ZGQCDQ8PFgIfAAUJ5L2V5bu65b"%"2BXZGQCDg8PFgIfAAUGJm5ic3A7ZGQCDw8PFgIfAAUGJm5ic3A7ZGQCEA8PFgIfAAUCNTZkZAIRDw8WAh8ABQYmbmJzcDtkZAISDw8WAh8ABQYmbmJzcDtkZAITDw8WAh8ABQYmbmJzcDtkZAIUDw8WAh8ABQYmbmJzcDtkZAIVDw8WAh8ABRLphqvmlofmiYDoqI7oq5blrqRkZAIWDw8WAh8ABQYmbmJzcDtkZAIDD2QWLmYPDxYCHwAFBDEwNDFkZAIBDw8WAh8ABTrkurrmlofmmqjnpL7mnIPnp5HlrbjpmaIgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGQCAg8PFgIfAAVH6Yar55mC5pqo55Sf54mp56eR5oqA5rOV5b6L56CU56m25omA56Kp5aOr54"%"2BtICAgICAgICAgICAgICAgICAgICAgICAgICBkZAIDDw8WAh8ABQkKMzQwMDAwMTZkZAIEDw8WAh8ABQYmbmJzcDtkZAIFDw8WAh8ABRjphqvol6XnlKLmpa3ms5Xlvovlr6bli5lkZAIGDw8WAh8ABQYmbmJzcDtkZAIHDw8WAh8ABQEyZGQCCA8PFgIfAAUBMmRkAgkPDxYCHwAFATJkZAIKDw8WAh8ABQIgIGRkAgsPDxYCHwAFA"%"2BWNimRkAgwPDxYCHwAFA"%"2BmBuGRkAg0PDxYCHwAFCeadjuW0h"%"2BWDlmRkAg4PDxYCHwAFBiZuYnNwO2RkAg8PDxYCHwAFBiZuYnNwO2RkAhAPDxYCHwAFBiZuYnNwO2RkAhEPDxYCHwAFAjU2ZGQCEg8PFgIfAAUGJm5ic3A7ZGQCEw8PFgIfAAUGJm5ic3A7ZGQCFA8PFgIfAAUGJm5ic3A7ZGQCFQ8PFgIfAAUS6Yar5paH5omA6KiO6KuW5a6kZGQCFg8PFgIfAAUGJm5ic3A7ZGQCBA9kFi5mDw8WAh8ABQQxMDQxZGQCAQ8PFgIfAAU65Lq65paH5pqo56S"%"2B5pyD56eR5a246ZmiICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRkAgIPDxYCHwAFR"%"2BmGq"%"2BeZguaaqOeUn"%"2BeJqeenkeaKgOazleW"%"2Bi"%"2BeglOeptuaJgOeiqeWjq"%"2BePrSAgICAgICAgICAgICAgICAgICAgICAgICAgZGQCAw8PFgIfAAUJCjM0MDAwMDI0ZGQCBA8PFgIfAAUGJm5ic3A7ZGQCBQ8PFgIfAAUS55Sf54mp5oqA6KGT5qaC6KuWZGQCBg8PFgIfAAUGJm5ic3A7ZGQCBw8PFgIfAAUBMWRkAggPDxYCHwAFATFkZAIJDw8WAh8ABQEyZGQCCg8PFgIfAAUCICBkZAILDw8WAh8ABQPljYpkZAIMDw8WAh8ABQPlv4VkZAINDw8WAh8ABRXkvZXlu7rlv5fjgIHlkLPmmI7mgZJkZAIODw8WAh8ABQI1NmRkAg8PDxYCHwAFBiZuYnNwO2RkAhAPDxYCHwAFBiZuYnNwO2RkAhEPDxYCHwAFBiZuYnNwO2RkAhIPDxYCHwAFBiZuYnNwO2RkAhMPDxYCHwAFBiZuYnNwO2RkAhQPDxYCHwAFBiZuYnNwO2RkAhUPDxYCHwAFBDgwMDVkZAIWDw8WAh8ABQYmbmJzcDtkZAIFD2QWLmYPDxYCHwAFBDEwNDFkZAIBDw8WAh8ABTflj6PohZTphqvlrbjpmaIgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGQCAg8PFgIfAAU45Y"%"2Bj6IWU6KGb55Sf5a2457O7ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZAIDDw8WAh8ABQkKMDAyODAwMDFkZAIEDw8WAh8ABQYmbmJzcDtkZAIFDw8WAh8ABQ"%"2Fmma7pgJrnlJ"%"2FnianlrbhkZAIGDw8WAh8ABQYmbmJzcDtkZAIHDw8WAh8ABQExZGQCCA8PFgIfAAUBM2RkAgkPDxYCHwAFATNkZAIKDw8WAh8ABQIwIGRkAgsPDxYCHwAFA"%"2BWNimRkAgwPDxYCHwAFA"%"2BW"%"2FhWRkAg0PDxYCHwAFCeadjumdkua"%"2BlGRkAg4PDxYCHwAFBiZuYnNwO2RkAg8PDxYCHwAFBiZuYnNwO2RkAhAPDxYCHwAFBiZuYnNwO2RkAhEPDxYCHwAFBiZuYnNwO2RkAhIPDxYCHwAFAzU2N2RkAhMPDxYCHwAFBiZuYnNwO2RkAhQPDxYCHwAFBiZuYnNwO2RkAhUPDxYCHwAFBDMxMDJkZAIWDw8WAh8ABRjlkIjplos66Jel5a2457WEQi7lj6PooZtkZAIGD2QWLmYPDxYCHwAFBDEwNDFkZAIBDw8WAh8ABTflj6PohZTphqvlrbjpmaIgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGQCAg8PFgIfAAU45Y"%"2Bj6IWU6KGb55Sf5a2457O7ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZAIDDw8WAh8ABQkKMDAyODAwMDJkZAIEDw8WAh8ABQYmbmJzcDtkZAIFDw8WAh8ABQzmma7pgJrljJblrbhkZAIGDw8WAh8ABQYmbmJzcDtkZAIHDw8WAh8ABQExZGQCCA8PFgIfAAUBMmRkAgkPDxYCHwAFATJkZAIKDw8WAh8ABQIwIGRkAgsPDxYCHwAFA"%"2BWNimRkAgwPDxYCHwAFA"%"2BW"%"2FhWRkAg0PDxYCHwAFCeWKieixq"%"2BW3nWRkAg4PDxYCHwAFBiZuYnNwO2RkAg8PDxYCHwAFAjU2ZGQCEA8PFgIfAAUGJm5ic3A7ZGQCEQ8PFgIfAAUGJm5ic3A7ZGQCEg8PFgIfAAUGJm5ic3A7ZGQCEw8PFgIfAAUGJm5ic3A7ZGQCFA8PFgIfAAUGJm5ic3A7ZGQCFQ8PFgIfAAUEODAwNmRkAhYPDxYCHwAFBiZuYnNwO2RkAgcPZBYuZg8PFgIfAAUEMTA0MWRkAgEPDxYCHwAFN"%"2BWPo"%"2BiFlOmGq"%"2BWtuOmZoiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZAICDw8WAh8ABTjlj6PohZTooZvnlJ"%"2Flrbjns7sgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRkAgMPDxYCHwAFCQowMDI4MDAwM2RkAgQPDxYCHwAFBiZuYnNwO2RkAgUPDxYCHwAFD"%"2BaZrumAmuW"%"2Fg"%"2BeQhuWtuGRkAgYPDxYCHwAFBiZuYnNwO2RkAgcPDxYCHwAFATFkZAIIDw8WAh8ABQEyZGQCCQ8PFgIfAAUBMmRkAgoPDxYCHwAFAjAgZGQCCw8PFgIfAAUD5Y2KZGQCDA8PFgIfAAUD5b"%"2BFZGQCDQ8PFgIfAAUb6JeN5LqtKExBTkUgVElNT1RIWSBKT1NFUEgpZGQCDg8PFgIfAAUCNTZkZAIPDw8WAh8ABQYmbmJzcDtkZAIQDw8WAh8ABQYmbmJzcDtkZAIRDw8WAh8ABQYmbmJzcDtkZAISDw8WAh8ABQYmbmJzcDtkZAITDw8WAh8ABQYmbmJzcDtkZAIUDw8WAh8ABQYmbmJzcDtkZAIVDw8WAh8ABRTlj6PohZQzRumajuair"%"2BaVmeWupGRkAhYPDxYCHwAFBiZuYnNwO2RkAggPZBYuZg8PFgIfAAUEMTA0MWRkAgEPDxYCHwAFN"%"2BWPo"%"2BiFlOmGq"%"2BWtuOmZoiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZAICDw8WAh8ABTjlj6PohZTooZvnlJ"%"2Flrbjns7sgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRkAgMPDxYCHwAFCQowMDI4MDAwNGRkAgQPDxYCHwAFBiZuYnNwO2RkAgUPDxYCHwAFFeeJmeenkeWFrOWFseihm"%"2BeUn"%"2BWtuGRkAgYPDxYCHwAFBiZuYnNwO2RkAgcPDxYCHwAFATFkZAIIDw8WAh8ABQEyZGQCCQ8PFgIfAAUBMmRkAgoPDxYCHwAFAjAgZGQCCw8PFgIfAAUD5Y2KZGQCDA8PFgIfAAUD5b"%"2BFZGQCDQ8PFgIfAAUJ5Zq05piO6IqzZGQCDg8PFgIfAAUGJm5ic3A7ZGQCDw8PFgIfAAUCNzhkZAIQDw8WAh8ABQYmbmJzcDtkZAIRDw8WAh8ABQYmbmJzcDtkZAISDw8WAh8ABQYmbmJzcDtkZAITDw8WAh8ABQYmbmJzcDtkZAIUDw8WAh8ABQYmbmJzcDtkZAIVDw8WAh8ABQQ4MDA0ZGQCFg8PFgIfAAUGJm5ic3A7ZGQCCQ8PFgIeB1Zpc2libGVoZGQCEw9kFgICAQ8PFgIfAAUP56"%"2BA5qyh6Kqq5piO77yaZGQCFQ8PFgIfAAVL5bu66K2w6J6i5bmV6Kej5p6Q5bqm6Kit5a6a54K6IDEwMjQqNzY45Lul5LiK77yM5Lul542y5b6X5pyA5L2z54CP6Ka95pWI5p6cZGQYAgUeX19Db250cm9sc1JlcXVpcmVQb3N0QmFja0tleV9fFgwFNGN0bDAwJENvbnRlbnRQbGFjZUhvbGRlcjEkTXlXZWVrU2VhcmNoMSRSYWRpb0J1dHRvbjEFNGN0bDAwJENvbnRlbnRQbGFjZUhvbGRlcjEkTXlXZWVrU2VhcmNoMSRSYWRpb0J1dHRvbjEFNGN0bDAwJENvbnRlbnRQbGFjZUhvbGRlcjEkTXlXZWVrU2VhcmNoMSRSYWRpb0J1dHRvbjIFNGN0bDAwJENvbnRlbnRQbGFjZUhvbGRlcjEkTXlXZWVrU2VhcmNoMSRSYWRpb0J1dHRvbjIFMWN0bDAwJENvbnRlbnRQbGFjZUhvbGRlcjEkTXlXZWVrU2VhcmNoMSRDaGVja0JveDEFMWN0bDAwJENvbnRlbnRQbGFjZUhvbGRlcjEkTXlXZWVrU2VhcmNoMSRDaGVja0JveDIFMWN0bDAwJENvbnRlbnRQbGFjZUhvbGRlcjEkTXlXZWVrU2VhcmNoMSRDaGVja0JveDMFMWN0bDAwJENvbnRlbnRQbGFjZUhvbGRlcjEkTXlXZWVrU2VhcmNoMSRDaGVja0JveDQFMWN0bDAwJENvbnRlbnRQbGFjZUhvbGRlcjEkTXlXZWVrU2VhcmNoMSRDaGVja0JveDUFMWN0bDAwJENvbnRlbnRQbGFjZUhvbGRlcjEkTXlXZWVrU2VhcmNoMSRDaGVja0JveDYFMWN0bDAwJENvbnRlbnRQbGFjZUhvbGRlcjEkTXlXZWVrU2VhcmNoMSRDaGVja0JveDcFJmN0bDAwJENvbnRlbnRQbGFjZUhvbGRlcjEkSW1hZ2VCdXR0b24xBSNjdGwwMCRDb250ZW50UGxhY2VIb2xkZXIxJEdyaWRWaWV3MQ88KwAKAgICAggC0gFke9QnoZnyfIYl89OY7ulvAfcA7Rc"%"3D&ctl00"%"24ContentPlaceHolder1"%"24DropDownListSmtr=#{year-1911}#{term}&ctl00"%"24ContentPlaceHolder1"%"24DropDownListSearchItem=courseName&ctl00"%"24ContentPlaceHolder1"%"24searchText=&ctl00"%"24ContentPlaceHolder1"%"24MyWeekSearch1"%"24DropDownListTimeStart=1&ctl00"%"24ContentPlaceHolder1"%"24MyWeekSearch1"%"24DropDownListTimeEnd=1" --compressed`
			rescue Exception => e
				next
			end
			
			puts '250 /'+page.to_s
			doc = Nokogiri::HTML(r)

			index = doc.css('table[id="ctl00_ContentPlaceHolder1_GridView1"] tr')
			
			index[1..-3].each do |row|
				datas = row.css('td')

				course_days = []
				course_periods = []
				course_locations = []

				14.upto(20) do |days|

					if(datas.css('td')[days].text.size > 1)
						0.upto(8) do |period|
							_period = datas.css('td')[days].text[period]
							if(_period.to_s.size>0)
								course_days << (days-13).to_s
								course_periods << _period
								course_locations << datas[21].text.strip
							end
						end
					end
				end

				course = {
							  name: "#{datas[5].text.strip}",
							  year: @year,
							  term: @term,
							  code: "#{@year}-#{@term}-#{datas[3].text.strip}",
							  department: "#{datas[1].text.strip}",
							  credits: "#{datas[8].text.strip}",
							  lecturer: "#{datas[13].text}",
							  day_1: course_days[0],
							  day_2: course_days[1],
							  day_3: course_days[2],
							  day_4: course_days[3],
							  day_5: course_days[4],
							  day_6: course_days[5],
							  day_7: course_days[6],
							  day_8: course_days[7],
							  day_9: course_days[8],
							  period_1: course_periods[0],
							  period_2: course_periods[1],
							  period_3: course_periods[2],
							  period_4: course_periods[3],
							  period_5: course_periods[4],
							  period_6: course_periods[5],
							  period_7: course_periods[6],
							  period_8: course_periods[7],
							  period_9: course_periods[8],
							  location_1: course_locations[0],
							  location_2: course_locations[1],
							  location_3: course_locations[2],
							  location_4: course_locations[3],
							  location_5: course_locations[4],
							  location_6: course_locations[5],
							  location_7: course_locations[6],
							  location_8: course_locations[7],
							  location_9: course_locations[8],
							}

				@after_each_proc.call(course: course) if @after_each_proc
				@courses << course
			end
		end

		@courses
	end

end

cwl =  TmuCourseCrawler.new(year: 2015, term: 1)
File.write('courses.json', JSON.pretty_generate(cwl.courses))
