require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'

require 'minitest/tagz'
Minitest::Tagz.choose_tags(*ENV['TAGS'].split(',')) if ENV['TAGS']
