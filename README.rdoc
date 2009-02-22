= Usher 

Tree-based router for Ruby on Rails.

This is a tree-based router (based on Ilya Grigorik suggestion). Turns out looking up in a hash and following a tree is faster than Krauter's massive regex approach, so why not? I said, Heck Yes, and here we are.

== Installation

  script/plugin install git://github.com/joshbuddy/usher.git

== TODO

* Make it integrate with merb
* Make it integrate with rails3

Looks about 20-50% faster than the router Rails ships with for non-trivial cases.

(Let me show you to your request)
