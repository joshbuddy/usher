= Usher 

Tree-based router for Ruby on Rails.

This is a tree-based router (based on Ilya Grigorik suggestion). Turns out looking up in a hash and following a tree is faster than Krauter's massive regex approach, so why not? I said, Heck Yes, and here we are.

== Rails

  script/plugin install git://github.com/joshbuddy/usher.git

== Rack

=== rackup.ru

  require 'usher'
  app = proc do |env|
    body = "Hi there #{env['usher.params'][:name]}"
    [
      200,          # Status code
      {             # Response headers
        'Content-Type' => 'text/plain',
        'Content-Length' => body.size.to_s,
      },
      [body]        # Response body
    ]
  end
  
  routes = Usher::Interface.for(:rack)
  routes.add('/hello/:name').to(app)
  run routes

=========

  >> curl http://127.0.0.1:3000/hello/samueltanders
  << Hi there samueltanders

== DONE

* add support for () optional parts

== TODO

* Make it integrate with merb
* Make it integrate with rails3
* Create decent DSL for use with rack

Looks about 20-50% faster than the router Rails ships with for non-trivial cases.

(Let me show you to your request)
