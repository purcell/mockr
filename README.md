# Mockr

Mockr is a pure Ruby library to support the Mock Objects approach to
unit testing, and is inspired by Java's JMock.

Several other Mock Object libraries exist for Ruby. In addition to its
unusually natural syntax for setting expectations, Mockr has two main
distinguishing features:

1. Support for the distinction between mocking and stubbing
2. A constraint-based mechanism for matching call parameters

MockR was initially presented by author Steve Purcell at the
2005 European Ruby Conference, and was written entirely test-first.

For more information or to contact the author, see
https://github.com/mockr

## Introduction

An instance of `Mockr::Mock` can be programmed with responses to
methods calls expected during the course of a unit test.  At the
end of the test, the instance can verify whether its expectations
were met, signalling a test failure if they were not.

Mocks distinguish between 'expected' method calls, which trigger
test failures if they are not made, and 'stub' method calls, which
are not verified.  'Expected' calls are typically those considered
critical to the proper use of the mocked class, and 'stub' calls are
those considered more flexible in their use.

## Example

The following is an example of a set of tests written entirely using MockR

```ruby
require 'test/unit'
require 'mockr'


class BurglarAlarmTest < Test::Unit::TestCase
  include Mockr::TestCaseHelpers

  def setup
    @laser_grid, @police_link = new_mock, new_mock
    @alarm = BurglarAlarm.new(@laser_grid.proxy, @police_link.proxy)
  end

  def test_police_station_not_contacted_if_grid_okay
    @laser_grid.expects.intact?.as { true }
    @alarm.check
  end

  def test_police_station_is_contacted_if_grid_not_okay
    @laser_grid.expects.intact?.as { false }
    @police_link.expects.incident("Grid breached")
    @alarm.check
  end

  def test_police_station_warned_if_grid_down
    @laser_grid.expects.intact?.as { raise IOError.new("comms down") }
    @police_link.expects.warning(/down/)   # A loose parameter constraint
    @alarm.check
  end

end
```

These tests would be satisfied by the following class:

```ruby
## Collaborates with a LaserGrid and a PoliceStationUplink
class BurglarAlarm
  def initialize(laser_grid, police_link)
    @laser_grid = laser_grid
    @police_link = police_link
  end

  def check
    begin
      @police_link.incident("Grid breached") unless @laser_grid.intact?
    rescue
      @police_link.warning("Grid down")
    end
  end
end
```

## Resources

* [Home page](https://github.com/purcell/mockr)

## Copyright

Copyright (c) 2005-2006 Steve Purcell.

## Licence

MockR is distributed under the same terms as Ruby itself.

<hr>

[![](http://api.coderwall.com/purcell/endorsecount.png)](http://coderwall.com/purcell)

[![](http://www.linkedin.com/img/webpromo/btn_liprofile_blue_80x15.png)](http://uk.linkedin.com/in/stevepurcell)

[Steve Purcell's blog](http://www.sanityinc.com/) // [@sanityinc on Twitter](https://twitter.com/sanityinc)
