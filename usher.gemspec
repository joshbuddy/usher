#!/usr/bin/env gem build
# encoding: utf-8

require "base64"

Gem::Specification.new do |s|
  s.name = "usher"
  s.version = "0.8.3"
  s.authors = ["Daniel Neighman", "Daniel Vartanov", "Jakub Šťastný", "Joshua Hull", "Davide D'Agostino"].sort
  s.homepage = "http://github.com/joshbuddy/usher"
  s.summary = "Pure ruby general purpose router with interfaces for rails, rack, email or choose your own adventure"
  s.cert_chain = nil
  s.email = Base64.decode64("am9zaGJ1ZGR5QGdtYWlsLmNvbQ==\n")
  s.has_rdoc = true

  # files
  s.files = `git ls-files`.split("\n") - `git ls-files spec/rails2_2`.split("\n") - `git ls-files spec/rails2_3`.split("\n")
  s.require_paths = ["lib"]

  # dependencies
  s.add_dependency "fuzzyhash", ">= 0.0.11"
  
  # development dependencies
  s.add_development_dependency "yard"
  s.add_development_dependency "rspec"
  s.add_development_dependency "code_stats"
  s.add_development_dependency "rake"
end
