#!/usr/bin/env ruby
# Smoke-test the renderer against a captured iNat API response.
require "json"
require_relative "inat_sync"

fixture = JSON.parse(File.read(File.expand_path("fixture_obs.json", __dir__)))
obs = fixture.fetch("results")

puts "=== Single-observation post ==="
puts render_post([obs.first], photo_size: "medium", post_date: "2026-05-19")

puts
puts "=== Multi-observation post (#{obs.size} obs) ==="
puts render_post(obs, photo_size: "medium", post_date: "2026-05-19")

puts
puts "=== Filename for multi-obs group ==="
puts post_filename("2026-05-19", obs)
