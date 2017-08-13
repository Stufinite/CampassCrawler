import subprocess, random
school = [
	'NUTC',
	'NSYSU',
	'NTPU',
	'NTU'
]

subprocess.call(['python', 'test.py', random.choice(school)])