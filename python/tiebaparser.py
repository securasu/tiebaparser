#!/usr/bin/env python
from datetime import datetime
import json
import os
import re
import sys
import time
import urllib2

class TiebaParser:
    BASE_RE = r'<div id="post_content_\d+" class="d_post_content j_d_post_content ">.+</div><br></cc>'
    EXP_RE = r'<div id="post_content_\d+" class="d_post_content j_d_post_content ">(.+)</div><br></cc>'
    PAGE_RE = r'<span class="red">(\d+)</span>'
    POST_RE = r'<span class="red" style="margin-right:3px">(\d+)<\/span>'
    URL_RE = r'tieba.baidu.com/p/\d+'

    CONFIG_FILE = 'only_lz.json'
    OUTPUT_FILE = 'only_lz.txt'

    def get_pages(self, html):
        m = re.search(self.PAGE_RE, html)
        if m:
            return int(m.group(1))

    def get_posts(self, html):
        m = re.search(self.POST_RE, html)
        if m:
            return int(m.group(1))

    def get_page(self, url):
        url += '?see_lz=1'
        raw = urllib2.urlopen(url).read()
        pages = self.get_pages(raw)
        posts = self.get_posts(raw)
        if self.check_update(posts):
            return ''
        h = {'posts': posts}
        self.save(self.CONFIG_FILE, json.dumps(h))
        rs = ''
        for i in range(1, pages + 1):
            page_url = url + '&pn=' + str(i)
            html = urllib2.urlopen(page_url).read()
            lst = re.findall(self.BASE_RE, html)
            for ele in lst:
                m = re.search(self.EXP_RE, ele)
                assert m
                rs = rs + m.group(1) + '\n'
        return rs

    def check_update(self, posts):
        if os.path.exists(self.CONFIG_FILE) == False:
            return False
        f = open(self.CONFIG_FILE, 'r')
        h = json.load(f)
        return h['posts'] <= posts

    def uri_check(self, uri):
        return re.search(self.URL_RE, uri)

    def save(self, filename, text):
        f = open(filename, 'w')
        f.write(text)
        f.close()

    def parse(self, uri):
        if self.uri_check(uri):
            text = self.get_page(uri)
            if text == '':
                return
            self.save(self.OUTPUT_FILE, text)
            print datetime.now().strftime('%a, %d %b %Y %H:%M:%S') + 'Updated'

if __name__ == '__main__':
    if sys.argv[1]:
        while True:
            TiebaParser().parse(sys.argv[1])
            time.sleep(5)
