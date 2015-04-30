# Minitest::Utils

Some utilities for your Minitest day-to-day usage.

Includes:

- A better reporter (see screenshot below)
- A [TestNotifier](http://github.com/fnando/test_notifier) reporter
- Some Rails niceties (set up FactoryGirl, WebMock and Capybara)
- Add a `t` and `l` methods (i18n)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'minitest-utils'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install minitest-utils

## Screenshots

![](https://raw.githubusercontent.com/fnando/minitest-utils/master/screenshots/light-failing.png)
![](https://raw.githubusercontent.com/fnando/minitest-utils/master/screenshots/light-success.png)
![](https://raw.githubusercontent.com/fnando/minitest-utils/master/screenshots/dark-failing.png)
![](https://raw.githubusercontent.com/fnando/minitest-utils/master/screenshots/dark-success.png)


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/minitest-utils/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
