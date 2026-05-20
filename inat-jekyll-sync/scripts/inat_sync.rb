#!/usr/bin/env ruby
# frozen_string_literal: true

# Sync iNaturalist observations into Jekyll posts.
#
# Reads:  _data/inat_published.yml (list of obs IDs already posted)
# Writes: _posts/YYYY-MM-DD-observations-<slug>.md (one post per group)
#         _data/inat_published.yml (manifest updated with new IDs)
#
# Usage:
#   ruby scripts/inat_sync.rb --user <iNat-login> [--dry-run] [--backfill]
#
# Stdlib only.

require "net/http"
require "uri"
require "json"
require "yaml"
require "erb"
require "fileutils"
require "optparse"
require "date"
require "digest"

API_HOST = "api.inaturalist.org"
PER_PAGE = 200
USER_AGENT = "jekyll-inat-sync/0.1 (+https://github.com/USER/REPO)"

# ---------- Manifest ----------

def load_manifest(path)
  return [] unless File.exist?(path)
  data = YAML.safe_load(File.read(path)) || []
  Array(data).map(&:to_i)
end

def save_manifest(path, ids)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, "# Auto-generated. iNaturalist observation IDs already published.\n" + YAML.dump(ids.sort.uniq))
end

# ---------- iNat API ----------

def fetch_page(user_login, id_above)
  uri = URI::HTTPS.build(
    host: API_HOST,
    path: "/v1/observations",
    query: URI.encode_www_form(
      user_login: user_login,
      per_page: PER_PAGE,
      order_by: "id",
      order: "asc",
      id_above: id_above
    )
  )
  req = Net::HTTP::Get.new(uri)
  req["User-Agent"] = USER_AGENT
  req["Accept"] = "application/json"
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
  raise "iNat API #{res.code}: #{res.body[0, 300]}" unless res.is_a?(Net::HTTPSuccess)
  JSON.parse(res.body)
end

def fetch_all_observations(user_login)
  all = []
  last_id = 0
  loop do
    page = fetch_page(user_login, last_id)
    results = page.fetch("results", [])
    break if results.empty?
    all.concat(results)
    last_id = results.map { |r| r["id"] }.max
    warn "  fetched #{all.size}/#{page['total_results']} (id_above=#{last_id})"
    break if results.size < PER_PAGE
    sleep 0.7 # be polite, well under 100/min
  end
  all
end

# ---------- Rendering ----------

POST_TEMPLATE = <<~ERB
  ---
  layout: post
  title: <%= title %>
  date: <%= post_date %>
  tags: [inaturalist]
  hero_photo: <%= hero_photo %>
  inat_obs_count: <%= obs.size %>
  inat_obs_ids: <%= obs.map { |o| o["id"] }.inspect %>
  ---
  <% obs.each do |o| %>
  <a id="obs-<%= o['id'] %>"></a>
  ## <%= common_name(o) %>

  *<%= scientific_name(o) %>*

  <%= place_line(o) %>

  <% photo_urls(o, photo_size).each do |url| -%>
  ![<%= common_name(o) %>](<%= url %>){: .inat-photo }
  <% end -%>
  <% if (o['description'] || '').strip != '' %>

  <%= o['description'] %>
  <% end %>

  [View on iNaturalist &rarr;](<%= o['uri'] %>)

  ---
  <% end %>
ERB

def common_name(o)
  taxon = o["taxon"] || {}
  taxon["preferred_common_name"] || taxon["name"] || "Unknown organism"
end

def scientific_name(o)
  (o["taxon"] || {})["name"] || ""
end

def place_line(o)
  parts = []
  parts << o["place_guess"] if o["place_guess"] && !o["place_guess"].empty?
  parts << o["observed_on"] if o["observed_on"]
  parts.join(" &middot; ")
end

def photo_urls(o, size)
  Array(o["photos"]).map { |p| (p["url"] || "").sub("square", size) }.reject(&:empty?)
end

def slugify(s)
  s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")[0, 60]
end

def post_filename(date_str, obs_group)
  hero = obs_group.first
  slug = slugify(common_name(hero))
  slug = "observations" if slug.empty?
  hash = Digest::SHA1.hexdigest(obs_group.map { |o| o["id"] }.sort.join(","))[0, 6]
  "#{date_str}-observations-#{slug}-#{hash}.md"
end

def render_post(obs_group, photo_size:, post_date:)
  hero = obs_group.first
  title =
    if obs_group.size == 1
      "Observation: #{common_name(hero)}"
    else
      taxa = obs_group.map { |o| common_name(o) }.uniq
      first_two = taxa.take(2).join(", ")
      "Observations: #{first_two}#{taxa.size > 2 ? " +#{taxa.size - 2} more" : ''}"
    end
  hero_photo = photo_urls(hero, photo_size).first || ""
  obs = obs_group
  ERB.new(POST_TEMPLATE, trim_mode: "-").result(binding)
end

# ---------- Main ----------

return unless $PROGRAM_NAME == __FILE__

options = {
  user: nil,
  dry_run: false,
  backfill: false,
  posts_dir: "_posts",
  manifest_path: "_data/inat_published.yml",
  photo_size: "medium"
}

OptionParser.new do |op|
  op.on("--user LOGIN")                                       { |v| options[:user] = v }
  op.on("--dry-run")                                           { options[:dry_run] = true }
  op.on("--backfill")                                          { options[:backfill] = true }
  op.on("--posts-dir DIR")                                     { |v| options[:posts_dir] = v }
  op.on("--manifest PATH")                                     { |v| options[:manifest_path] = v }
  op.on("--photo-size SIZE", %w[square small medium large original]) { |v| options[:photo_size] = v }
end.parse!

abort "Missing --user" unless options[:user]

published = load_manifest(options[:manifest_path])
puts "Manifest: #{published.size} obs already published."

puts "Fetching observations for @#{options[:user]}..."
all = fetch_all_observations(options[:user])
puts "Fetched #{all.size} total observations."

new_obs = all.reject { |o| published.include?(o["id"]) }
puts "New observations: #{new_obs.size}"

if new_obs.empty?
  puts "Nothing to do."
  exit 0
end

# Group: by observed_on date in backfill mode, else single post per run.
groups =
  if options[:backfill]
    new_obs.group_by { |o| o["observed_on"] || o["created_at"][0, 10] }
  else
    today = Date.today.strftime("%Y-%m-%d")
    { today => new_obs }
  end

FileUtils.mkdir_p(options[:posts_dir]) unless options[:dry_run]

written = []
groups.sort.each do |date_str, group|
  filename = post_filename(date_str, group)
  path = File.join(options[:posts_dir], filename)
  body = render_post(group, photo_size: options[:photo_size], post_date: date_str)
  if options[:dry_run]
    puts "[dry-run] would write #{path} (#{group.size} obs)"
  else
    File.write(path, body)
    puts "Wrote #{path} (#{group.size} obs)"
  end
  written << path
end

unless options[:dry_run]
  updated = (published + new_obs.map { |o| o["id"] }).sort.uniq
  save_manifest(options[:manifest_path], updated)
  puts "Manifest updated: #{updated.size} ids."
end

puts "Done. #{written.size} post(s) written."
