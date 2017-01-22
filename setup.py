from distutils.core import setup

setup(
    name = 'campasscrawler',
    packages = ['campasscrawler'],
    version = '1.0',
    description = 'Collections of Crawlers for Taiwan Universities.',
    author = 'davidtnfsh',
    author_email = 'davidtnfsh@gmail.com',
    url = 'https://github.com/Stufinite/campasscrawler',
    download_url = 'https://github.com/Stufinite/campasscrawler/archive/v1.0.tar.gz',
    keywords = ['Crawler', 'campass'],
    classifiers = [],
    license='',
    install_requires=[
        'requests',
        'simplejson',
        'pyprind',
        'pymongo',
    ],
    zip_safe=True
)
