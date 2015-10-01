# HeapInspect

A CLI for analyzing Ruby Heap dumps. Thanks to [Sam Saffron](http://samsaffron.com/archive/2015/03/31/debugging-memory-leaks-in-ruby) for the idea and initial code.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'heap_inspect'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install heap_inspect

## Usage

Step 1) Generate a heap dump. You could [do this manually](http://samsaffron.com/archive/2015/03/31/debugging-memory-leaks-in-ruby). Or you can use a tool like [derailed_benchmarks](https://github.com/schneems/derailed_benchmarks)

Step 2) Once you've got the heap dump, you can analyze it using this CLI:

```
$ heap_inspect read tmp/2015-10-01T10:18:59-05:00-heap.dump

Generation:  0 object count: 209191
Generation: 14 object count: 407
Generation: 15 object count: 638
Generation: 16 object count: 748
Generation: 17 object count: 1023
Generation: 18 object count: 805
# ...
```

Generally early generations will have a high object count as an app is initialized. Over time however, the object count should stabalize. If however you see it spike up, you can drill down into a specific generation. In the previous example, the 17'th generation looks strangely large, you can drill into it:


```
$ heap_inspect read tmp/2015-10-01T10:18:59-05:00-heap.dump 17
    Analyzing Heap (Generation: 17)
    -------------------------------

    allocated by memory (in bytes)
    ==============================
    /Users/richardschneeman/Documents/projects/codetriage/app/views/layouts/application.html.slim:1 (Memory: 377065, Count: 1 )
    /Users/richardschneeman/.gem/ruby/2.2.3/gems/actionview-4.2.3/lib/action_view/template.rb:296 (Memory: 35814, Count: 67 )
    /Users/richardschneeman/.gem/ruby/2.2.3/gems/activerecord-4.2.3/lib/active_record/attribute.rb:5 (Memory: 30672, Count: 426 )
```

You can also use T-Lo's online JS based [Heap Analyzer](http://tenderlove.github.io/heap-analyzer/) for visualizations.

## Development

After checking out the repo, run `$ bundle install` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/schneems/heap_inspect. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

