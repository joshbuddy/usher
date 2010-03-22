#!/usr/bin/env gem build
# encoding: utf-8

require "base64"

Gem::Specification.new do |s|
  s.name = "usher"
  s.version = "0.7.0"
  s.authors = ["Daniel Neighman", "Daniel Vartanov", "Jakub Šťastný", "Joshua Hull"]
  s.homepage = "http://github.com/joshbuddy/usher"
  s.summary = "Pure ruby general purpose router with interfaces for rails, rack, email or choose your own adventure"
  s.cert_chain = nil
  s.email = Base64.decode64("am9zaGJ1ZGR5QGdtYWlsLmNvbQ==\n")
  s.has_rdoc = true

  # files
  s.files = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  # dependencies
  s.add_dependency "fuzzyhash", ">= 0.0.11"

  # RubyForge
  s.rubyforge_project = "joshbuddy-usher"
end
