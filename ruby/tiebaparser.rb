#!/usr/bin/env ruby
require 'nokogiri'
require 'open-uri'

class TiebaParser
  module Constants
    PAGE_INFO = '//div[@id = "thread_theme_5"]' \
                '/div[@class = "l_thread_info"]' \
                '/ul[@class = "l_posts_num"]' \
                '/li[@class = "l_reply_num"]' \
                '/span'
    POST      = '//cc' \
                '/div[@class = "d_post_content j_d_post_content "]'
    TITLE     = '//div' \
                '/h1[@class = "core_title_txt  "]'

    URI_RE    = %r[http://tieba.baidu.com/p/\d+]
    SEE_LZ    = 'see_lz=1'
    PN        = 'pn='
  end

  @post_num
  @uri

  def initialize uri
    @post_num = 0
    @uri = uri
  end

  def get_thread_info doc
    infos = []
    doc.xpath(Constants::PAGE_INFO).each do |link|
      infos << link.content.to_i
    end
    infos
  end

  def get_title doc
    title = nil
    doc.xpath(Constants::TITLE).each do |link|
      title = link.content.strip
    end
    title
  end

  def get_posts doc
    posts = []
    doc.xpath(Constants::POST).each do |link|
      posts << link.content.strip
    end
    posts
  end

  def get_nokogiri rawdata
    Nokogiri::HTML(rawdata)
  end

  def parse_and_save
    raise 'the uri is not a thread of tieba' unless Constants::URI_RE =~ @uri
    uri = "#{@uri}?#{Constants::SEE_LZ}"
    doc = get_nokogiri(open(uri))
    title = get_title(doc)
    post_num, page_num = get_thread_info(doc)
    print "total #{post_num} posts, #{page_num} pages\n" \
         "now parsing page 1"
    posts = get_posts(doc)
    2.upto page_num do |p|
      print "\rnow parsing page #{p}"
      p_uri = "#{uri}&#{Constants::PN}#{p}"
      posts = posts + get_posts(get_nokogiri(open(p_uri)))
    end
    File.open("#{title}.txt", "w") do |f|
      f.puts posts
    end
    @post_num = post_num
    puts
  end

  def have_update?
    uri = "#{@uri}?#{Constants::SEE_LZ}"
    doc = get_nokogiri(open(uri))
    post_num, _ = get_thread_info(doc)
    post_num > @post_num
  end
end

if $0 == __FILE__ && ARGV.length > 0
  parser = TiebaParser.new ARGV[0]
  parser.parse_and_save
end
