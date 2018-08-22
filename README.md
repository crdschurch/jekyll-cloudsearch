# jekyll-cloudsearch

[![Build Status](https://travis-ci.org/crdschurch/jekyll-cloudsearch.svg?branch=master)](https://travis-ci.org/crdschurch/jekyll-cloudsearch)

`jekyll-cloudsearch` is a Jekyll plugin that publishes site content to AWS Cloudsearch. It assumes content is aggregated from Contentful and stored as collection objects within a Jekyll instance.

## Installation

Add the following to your `Gemfile` and bundle...

```ruby
gem "jekyll-cloudsearch", "~> 0.0.1", git: 'https://github.com/crdschurch/jekyll-cloudsearch.git'
```

## Usage

`jekyll-cloudsearch` builds the search index automatically for all rendered collections, when enabled (NOTE: it is disabled by default). You can enable this functionality by passing the following flag to your build command...

```
bundle exec jekyll build -- --cloudsearch
```

## Environment Variables

The following environment variables are required. Please make sure they are exported to the same scope in which your Jekyll commands are run.

| Name | Description |
| ----- | ------ |
| `CONTENTFUL_MANAGEMENT_TOKEN` | Access token for Contentful's Management API |
| `CONTENTFUL_SPACE_ID` | Contentful Space ID |
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `AWS_REGION` | AWS region |
| `AWS_CLOUDSEARCH_ENDPOINT` | Search endpoint for Cloudsearch domain |
| `AWS_CLOUDSEARCH_BASE_URL` | Base URL for all documents passed to Cloudsearch |

## License

This project is licensed under the [3-Clause BSD License](https://opensource.org/licenses/BSD-3-Clause).
