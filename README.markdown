# Usher

Tree-based router library. Useful for (specifically) for Rails and Rack, but probably generally useful for anyone interested in doing routing. Based on Ilya Grigorik suggestion, turns out looking up in a hash and following a tree is faster than Krauter's massive regex approach.

## The future

This router has been an awful lot of fun, but a much more powerful, faster and kind-to-memory router is now available at.

* [http://github.com/joshbuddy/http_router](http://github.com/joshbuddy/http_router)

It has almost all the of the features of Usher, and quite a few more Usher doesn't have. It doesn't support Rails 2.x, and likely, never will. But if you're doing Rack routing, or Sinatra, I think you'll be quite pleased with it. Cheers!

## Features

* Understands single and path-globbing variables
* Understands arbitrary regex variables
* Arbitrary HTTP header requirements
* No optimization phase, so routes are always alterable after the fact
* Understands Proc and Regex transformations, validations
* Really, really fast
* Relatively light and happy code-base, should be easy and fun to alter (it hovers around 1,000 LOC, 800 for the core)
* Interface and implementation are separate, encouraging cross-pollination
* Works in 1.9!

## Projects using or other references to Usher

* [http://github.com/Tass/CRUDtree](http://github.com/Tass/CRUDtree) - RESTful resource mapper
* [http://github.com/padrino/padrino-framework](http://github.com/padrino/padrino-framework) - Web framework
* [http://github.com/botanicus/rango](http://github.com/botanicus/rango) - Web framework
* [http://github.com/hassox/pancake](http://github.com/hassox/pancake) - Web framework
* [http://github.com/eddanger/junior](http://github.com/eddanger/junior) - Web framework
* [http://github.com/lifo/cramp](http://github.com/lifo/cramp) - Web framework
* [http://yehudakatz.com/2009/08/26/how-to-build-sinatra-on-rails-3/](http://yehudakatz.com/2009/08/26/how-to-build-sinatra-on-rails-3/) - How to Build Sinatra on Rails 3

Any probably more!

## Route format

From the rdoc:

Creates a route from `path` and `options`

### `path`
A path consists a mix of dynamic and static parts delimited by `/`

#### Dynamic
Dynamic parts are prefixed with either `:`, `*`.  :variable matches only one part of the path, whereas `*variable` can match one or
more parts.

<b>Example:</b>
`/path/:variable/path` would match

* `/path/test/path`
* `/path/something_else/path`
* `/path/one_more/path`

In the above examples, `test`, `something_else` and `one_more` respectively would be bound to the key `:variable`.
However, `/path/test/one_more/path` would not be matched.

<b>Example:</b>
`/path/*variable/path` would match

* `/path/one/two/three/path`
* `/path/four/five/path`

In the above examples, `['one', 'two', 'three']` and `['four', 'five']` respectively would be bound to the key `:variable`.

As well, variables can have a regex matcher.

<b>Example:</b>
`/product/{:id,\d+}` would match

* `/product/123`
* `/product/4521`

But not
* `/product/AE-35`

As well, the same logic applies for * variables as well, where only parts matchable by the supplied regex will
actually be bound to the variable

Variables can also have a greedy regex matcher. These matchers ignore all delimiters, and continue matching for as long as much as their
regex allows.

<b>Example:</b>
`/product/{!id,hello/world|hello}` would match

* `/product/hello/world`
* `/product/hello`


#### Static

Static parts of literal character sequences. For instance, `/path/something.html` would match only the same path.
As well, static parts can have a regex pattern in them as well, such as `/path/something.{html|xml}` which would match only
`/path/something.html` and `/path/something.xml`

#### Optional sections

Sections of a route can be marked as optional by surrounding it with brackets. For instance, in the above static example, `/path/something(.html)` would match both `/path/something` and `/path/something.html`.

#### One and only one sections

Sections of a route can be marked as "one and only one" by surrounding it with brackets and separating parts of the route with pipes.
For instance, the path, `/path/something(.xml|.html)` would only match `/path/something.xml` and
`/path/something.html`. Generally its more efficent to use one and only sections over using regex.

### `options`
* `requirements` - After transformation, tests the condition using #===. If it returns false, it raises an `Usher::ValidationException`
* `conditions` - Accepts any of the `request_methods` specificied in the construction of Usher. This can be either a `string` or a regular expression.
* `default_values` - Provides values for variables in your route for generation. If you're using URL generation, then any values supplied here that aren't included in your path will be appended to the query string.
* `priority` - If there are two routes which equally match, the route with the highest priority will match first.
* Any other key is interpreted as a requirement for the variable of its name.

## Rails

    script/plugin install git://github.com/joshbuddy/usher.git

In your config/initializers/usher.rb (create if it doesn't exist) add:

    Usher::Util::Rails.activate

## Rack

### `config.ru`

    require 'usher'
    app # proc do |env|
      body # "Hi there #{env['usher.params'][:name]}"
      [
        200,          # Status code
        {             # Response headers
          'Content-Type' #> 'text/plain',
          'Content-Length' #> body.size.to_s,
        },
        [body]        # Response body
      ]
    end
   
    routes # Usher::Interface.for(:rack) do
      add('/hello/:name').to(app)
    end
   
    run routes

------------

    >> curl http://127.0.0.1:3000/hello/samueltanders
    << Hi there samueltanders


## Sinatra

In Sinatra, you get the extra method, `generate`, which lets you generate a url. Name your routes with `:name` when you define them.

    require 'rubygems'
    require 'usher'
    require 'sinatra'
    
    Usher::Interface.for(:sinatra)
    
    get '/hi', :name #> :hi do
      "Hello World! #{generate(:hi)}"
    end

(Let me show you to your request)
