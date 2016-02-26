# Minitest::Tagz

[![Build Status](https://travis-ci.org/backupify/minitest-tagz.svg)](https://travis-ci.org/backupify/minitest-tagz)
[![Code Climate](https://codeclimate.com/github/backupify/minitest-tagz/badges/gpa.svg)](https://codeclimate.com/github/backupify/minitest-tagz)
[![Gem Version](https://badge.fury.io/rb/minitest-tagz.svg)](http://badge.fury.io/rb/minitest-tagz)

yet another tags implementation for Minitest

## Requirements

* Ruby 2.0.0+

## Installation

Add this line to your application's Gemfile:

```rb
gem 'minitest-tagz'
```

## Setup

In your `test_helper.rb` you'll need to require `Minitest::Tagz`. You'll also
want to tell `Tagz` which tags you want to use. I suggest using the `TAGS` environment
variable:

```rb
require 'minitest/tagz'
Minitest::Tagz.choose_tags(*ENV['TAGS'].split(',')) if ENV['TAGS']
```

Then, for example, you can run all tests with the `:fast` and `:login` tags:

```rb
bundle exec rake test TAGS=fast,login
```

You can also run all test without a particular tag or mix any subset.
Below we run all the `:fast` tags, but not the `:login` tags

```rb
bundle exec rake test TAGS=-login,fast
```

Here's another example which will allow you to drop in a `:focus` tag wherever you want:

```rb
require 'minitest/tagz'
tags = ENV['TAGS'].split(',') if ENV['TAGS']
tags ||= []
tags << 'focus'
Minitest::Tagz.choose_tags(*tags, run_all_if_no_match: true)
```

## Usage

`Minitest::Tagz` works with both `Minitest::Test` and `Minitest::Spec`. You can declare
tags by using the `tag` helper.

```rb
# Using Minitest::Spec
class MySpec < Minitest::Spec
  tag :fast, :unit
  it 'should run' do
    assert true
  end

  tag :fast
  it 'should not run' do
    refute true
  end

  it 'also should not run' do
    refute true
  end
end

# Using Minitest::Test
class MyTest < Minitest::Test
  tag :fast
  def test_my_stuff
    assert true
  end
end
```

With `Minitest::Spec` adding tags to a `describe` will add the tags to all of the
tests in the block:

```rb
class MySpec < Minitest::Spec
  tag :login
  describe 'all tests in this are tagged with :login' do
    it 'tests this' do
      assert true
    end

    it 'also tests this' do
      assert true
    end
  end
end
```

You can also use the `run_all_if_no_match` option to do something like always have a `:focus` tag on-demand:

```rb
Minitest::Tagz.choose_tags(*ENV['TAGS'].split(','), run_all_if_no_match: true) if ENV['TAGS']
```

This is how we add `tag :focus` in our projects:

```rb
require 'minitest/tagz'

tags = ENV['TAGS'].split(',') if ENV['TAGS']
tags ||= []
tags << 'focus'
Minitest::Tagz.choose_tags(*tags, run_all_if_no_match: true)
```

## Debugging

You can save a reference to the tagger and watch the internal state machine:

```rb
tagger = tag :focus
it 'should work' do
  require 'rubygems'; require 'pry'; binding.pry
end

pry(main)> tagger
#=> #<Minitest::Tagz::Tagger:0x007fa296102008 @owner=#<Class:0x007fa2957317b8>, @patchers=[Minitest::Tagz::MinitestPatcher], @pending_tags=[:focus], @state="applying_tags">
```

## Contributing

1. Fork it ( https://github.com/backupify/minitest-tagz/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
