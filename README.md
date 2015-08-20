# Minitest::Tagz

yet another tags implementation for Minitest

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'minitest-tagz'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install minitest-tagz

## Usage

```rb
# spec_helper.rb
require 'minitest/tagz'

Minitest::Tagz.patch_minitest
Minitest::Tagz.choose_tags(*ENV['TAGS'].split(',')) if ENV['TAGS']

# my_spec.rb
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

# command line
bundle exec rake test TAGS=fast,unit
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/backupify/minitest-tagz/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
