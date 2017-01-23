from distutils.core import setup

setup(
    name = 'CampassCrawler',
    packages = ['CampassCrawler'],
    version = '1.3',
    description = 'Collections of Crawlers for Taiwan Universities.',
    author = 'davidtnfsh',
    author_email = 'davidtnfsh@gmail.com',
    url = 'https://github.com/Stufinite/CampassCrawler',
    download_url = 'https://github.com/Stufinite/CampassCrawler/archive/v1.3.tar.gz',
    keywords = ['Crawler', 'campass'],
    classifiers = [],
    license='GNU GPLv3',
    install_requires=[
        'requests',
        'simplejson',
        'pyprind',
        'pymongo',
    ],
    zip_safe=True
)
