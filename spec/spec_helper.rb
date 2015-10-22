require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'

require 'shoulda-context'

require 'minitest/tagz'
Minitest::Tagz.choose_tags(*ENV['TAGS'].split(',')) if ENV['TAGS']
