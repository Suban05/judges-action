# frozen_string_literal: true

# MIT License
#
# Copyright (c) 2024 Zerocracy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'fbe/fb'
require 'fbe/octo'
require 'fbe/github_graph'
require 'fbe/unmask_repos'

unless Fbe.fb.query(
  "(and
    (eq what '#{$judge}')
    (gt when (minus (to_time (env 'TODAY' '#{Time.now.utc.iso8601}')) '1 days')))"
).each.to_a.empty?
  $loog.debug("#{$judge} statistics have recently been collected, skipping now")
  return
end

f = Fbe.fb.insert
f.what = $judge
f.when = Time.now

# Total number of repositories in the project:
total = 0
Fbe.unmask_repos.each do |_|
  total += 1
end
f.total_repositories = total

# Total number of releases ever made:
total = 0
Fbe.unmask_repos.each do |repo|
  Fbe.octo.releases(repo).each do |_|
    total += 1
  end
end
f.total_releases = total

# Total number of stars and forks for all repos:
stars = 0
forks = 0
Fbe.unmask_repos.each do |repo|
  Fbe.octo.repository(repo).then do |json|
    stars += json[:stargazers_count]
    forks += json[:forks]
  end
end
f.total_stars = stars
f.total_forks = forks

# Total number of issues and pull requests for all repos
issues = 0
pulls = 0
Fbe.unmask_repos.each do |repo|
  json = Fbe.github_graph.total_issues_and_pulls(*repo.split('/'))
  issues += json['issues']
  pulls += json['pulls']
end
f.total_issues = issues
f.total_pulls = pulls
