require 'minitest/tagz'

tags = ENV['TAGS'].split(',') if ENV['TAGS']
tags ||= ['focus']
Minitest::Tagz.choose_tags(*tags, run_all_if_no_match: true)
