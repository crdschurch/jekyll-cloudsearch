# jekyll-cloudsearch

[![Build Status](https://travis-ci.org/crdschurch/jekyll-cloudsearch.svg?branch=master)](https://travis-ci.org/crdschurch/jekyll-cloudsearch)

`jekyll-cloudsearch` is a Jekyll plugin that publishes site content to AWS Cloudsearch.

## Installation

Add the following to your `Gemfile` and bundle...

```ruby
gem "jekyll-cloudsearch", "~> 0.0.1", git: 'https://github.com/crdschurch/jekyll-cloudsearch.git'
```

## Environment Variables

The following environment variables are required. Please make sure they are exported to the same scope in which your Jekyll commands are run.

| Name | Description | Default |
| ----- | ------ | ------- |
| `CONTENTFUL_MANAGEMENT_TOKEN` | Access token for Contentful's Management API | |
| `CONTENTFUL_SPACE_ID` | ID specifying Contentful Space | |

## License

This project is licensed under the [3-Clause BSD License](https://opensource.org/licenses/BSD-3-Clause).
