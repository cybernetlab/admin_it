# AdminIt

Administrative backend for ruby projects.

[Russian version of this document](README_RU.md)

# Installation

```sh
gem install admin_it
```

or if you using `bundler`:

```ruby
# Gemfile
gem 'admin_it'
```

```sh
bundle install
```

# Configuration

# Usage

# Todo

* use_fields not working in root resource context
* human-readable date and time fields
* Test coverage
* Entities editing/creating

## Longtime plans

* Sinatra support

# Changes

`1.0.6`

* fixed: [#1](/../../issues/1)

`1.0.5`

* font-awesome asset path fix

`1.0.4`

* font-awesome fix

`1.0.3`

* assets fix

`1.0.2`

* routes moved to config folder
* fixed issues with pundit and devise

`1.0.1`

* wrap_it link in Gemfile fixed

`1.0.0` - pre-release

* active_record support
* filters
* sorting

`0.0.1` - first version

# License

The MIT License (MIT)

Copyright (c) 2014 Alexey Ovchinnikov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
