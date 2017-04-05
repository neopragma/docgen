# Docgen

Proof of concept to apply custom updates to template files and output the resulting file in any of several formats, including text, HTML, PDF, LaTeX, and others.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'docgen'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install docgen

## Usage

The gem takes a template document that may contain placeholders for content substitution, and applies substitution values to produce a customized output document. The substitution values are defined in a database as key-value pairs. The placeholders in the template documents contain the key values matching entries in the database. 

Given a template document like this

```
Hello, ::name::. It's a ::quality:: day today, isn't it?
```

and substitution values like this

```
name => Marcia
quality => dismal
```

then a call like this

```
docgen.gen 'pdf', template_text
```

results in a PDF file containing the text

```
Hello, Marcia. It's a dismal day today, isn't it?
```

The code is under development, so it's premature to write comprehensive documentation in a refined way. See the file ```docgen_spec.rb``` for working examples of usage.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/docgen. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

