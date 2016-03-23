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

## Defining tests

This gem adds the `Minitest::Test.test` method, so you can easy define your methods like the following:

```ruby
class SampleTest < Minitest::Test
  test 'useless test' do
    assert true
  end
end
```

This is equivalent to defining a method named `test_useless_test`. You can also skip the block, which will define a [flunk](https://github.com/seattlerb/minitest/blob/77120c5b2511c4665610cda06c8058c801b28e7f/lib/minitest/assertions.rb#L477-L480) call.

You can also define `setup` and `teardown` steps.

```ruby
class SampleTest < Minitest::Test
  setup do
    DB.connect
  end

  teardown do
    DB.disconnect
  end

  test 'useless test' do
    assert true
  end
end
```

Finally, you can also use `let`.

```ruby
class SampleTest < Minitest::Test
  let(:token) { 'secret' }

  test 'set token' do
    assert_equal 'secret', token
  end
end
```

## Screenshots

![](https://raw.githubusercontent.com/fnando/minitest-utils/master/screenshots/light-failing.png)
![](https://raw.githubusercontent.com/fnando/minitest-utils/master/screenshots/light-success.png)
![](https://raw.githubusercontent.com/fnando/minitest-utils/master/screenshots/dark-failing.png)
![](https://raw.githubusercontent.com/fnando/minitest-utils/master/screenshots/dark-success.png)

## Rails extensions

minitest-utils sets up some things for your Rails application. Just load `minitest/utils/rails` to set up:

- [Capybara](https://github.com/jnicklas/capybara): includes `Capybara::DSL`, sets default driver before every test, resets session and creates a helper method for setting JavaScript driver. If you have [poltergeist](https://github.com/teampoltergeist/poltergeist) installed, it will be used as the default JavaScript driver.
- [FactoryGirl](https://github.com/thoughtbot/factory_girl): adds methods to `ActiveSupport::TestCase`.
- [WebMock](https://github.com/bblimke/webmock): disables external requests (except for codeclimate) and tracks all requests on `WebMock.requests`.
- locale routes: sets `Rails.application.routes.default_url_options[:locale]` with your current locale.
- [DatabaseCleaner](https://github.com/DatabaseCleaner/database_cleaner): runs `DatabaseCleaner.start` and `DatabaseCleaner.clean` before and after every test respectively.
- Other: `t` and `l` alias to I18n.

```ruby
class SignupTest < ActionDispatch::IntegrationTtest
  use_javascript! #=> enables JavaScript driver
end
```

Also, if you're using routes like `:locale` scope, you can load this file to automatically set your route's `:locale` param.

```ruby
require 'minitest/utils/rails/locale'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/fnando/minitest-utils/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
