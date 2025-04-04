# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

require 'factbase'
require 'json'
require 'judges/options'
require 'loog'
require 'webmock/minitest'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestLabelWasAttached < Minitest::Test
  def test_catches_label_event
    WebMock.disable_net_connect!
    stub_request(:get, 'https://api.github.com/repos/foo/foo').to_return(
      body: { id: 42, full_name: 'foo/foo' }.to_json, headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/repositories/42').to_return(
      body: { id: 42, full_name: 'foo/foo' }.to_json, headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/repositories/42/issues/42/timeline?per_page=100').to_return(
      body: [{ event: 'labeled', label: { name: 'bug' }, actor: { id: 42 }, created_at: Time.now }].to_json, headers: {
        'content-type': 'application/json'
      }
    )
    fb = Factbase.new
    op = fb.insert
    op.what = 'issue-was-opened'
    op.repository = 42
    op.issue = 42
    load_it('label-was-attached', fb)
    load(File.join(__dir__, '../../judges/label-was-attached/label-was-attached.rb'))
    f = fb.query('(eq what "label-was-attached")').each.to_a.first
    refute_nil(f)
    assert_equal(42, f.who)
    assert_equal('bug', f.label)
  end

  def test_removes_lost_issue
    WebMock.disable_net_connect!
    stub_request(:get, 'https://api.github.com/repos/foo/foo').to_return(
      body: { id: 44, full_name: 'foo/foo' }.to_json, headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/repositories/44').to_return(
      body: { id: 44, full_name: 'foo/foo' }.to_json, headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/repositories/44/issues/44/timeline?per_page=100').to_return(
      status: 404,
      body: [
        {
          message: 'Not Found',
          documentation_url: 'https://docs.github.com/rest/issues/timeline#list-timeline-events-for-an-issue',
          status: '404'
        }
      ].to_json,
      headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/rate_limit').to_return(
      status: 200, body: '', headers: {}
    )
    fb = Factbase.new
    op = fb.insert
    op.what = 'issue-was-opened'
    op.repository = 44
    op.issue = 44
    op.where = 'github'
    load_it('label-was-attached', fb)
    f = fb.query('(eq what "issue-was-opened")').each.to_a
    assert_equal(0, f.count)
    f = fb.query('(eq issue 44)').each.to_a
    assert_equal(0, f.count)
  end

  def test_does_not_remove_labeled_issue
    WebMock.disable_net_connect!
    stub_request(:get, 'https://api.github.com/repos/foo/foo').to_return(
      body: { id: 44, full_name: 'foo/foo' }.to_json, headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/repositories/44').to_return(
      body: { id: 44, full_name: 'foo/foo' }.to_json, headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/repositories/44/issues/44/timeline?per_page=100').to_return(
      status: 404,
      body: [
        {
          message: 'Not Found',
          documentation_url: 'https://docs.github.com/rest/issues/timeline#list-timeline-events-for-an-issue',
          status: '404'
        }
      ].to_json,
      headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/repositories/44/issues/45/timeline?per_page=100').to_return(
      status: 404,
      body: [
        {
          event: 'labeled',
          label: { name: 'bug' },
          actor: { id: 45 },
          created_at: Time.now
        }
      ].to_json,
      headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/rate_limit').to_return(
      status: 200, body: '', headers: {}
    )
    fb = Factbase.new
    op = fb.insert
    op.what = 'issue-was-opened'
    op.repository = 44
    op.issue = 44
    op.where = 'github'
    op = fb.insert
    op.what = 'issue-was-opened'
    op.repository = 44
    op.issue = 45
    op.where = 'github'
    load_it('label-was-attached', fb)
    f = fb.query('(eq what "issue-was-opened")').each.to_a
    assert_equal(1, f.count)
    assert_equal(45, f.first.issue)
    assert_equal('issue-was-opened', f.first.what)
    assert_nil(f[1])
    f = fb.query('(eq issue 44)').each.to_a
    assert_equal(0, f.count)
  end

  def test_does_not_remove_issue_from_other_repository
    WebMock.disable_net_connect!
    stub_request(:get, 'https://api.github.com/repos/foo/foo').to_return(
      body: { id: 50, full_name: 'foo/foo' }.to_json, headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/repositories/50').to_return(
      body: { id: 50, full_name: 'foo/foo' }.to_json, headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/repos/bar/bar').to_return(
      body: { id: 55, full_name: 'bar/bar' }.to_json, headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/repositories/55').to_return(
      body: { id: 55, full_name: 'bar/bar' }.to_json, headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/repositories/50/issues/46/timeline?per_page=100').to_return(
      status: 404,
      body: [
        {
          message: 'Not Found',
          documentation_url: 'https://docs.github.com/rest/issues/timeline#list-timeline-events-for-an-issue',
          status: '404'
        }
      ].to_json,
      headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/repositories/55/issues/46/timeline?per_page=100').to_return(
      body: [
        {
          event: 'labeled',
          label: { name: 'bug' },
          actor: { id: 46 },
          created_at: Time.now
        }
      ].to_json,
      headers: {
        'content-type': 'application/json'
      }
    )
    stub_request(:get, 'https://api.github.com/rate_limit').to_return(
      status: 200, body: '', headers: {}
    )
    fb = Factbase.new
    op = fb.insert
    op.what = 'issue-was-opened'
    op.repository = 50
    op.issue = 46
    op.where = 'github'
    op = fb.insert
    op.what = 'issue-was-opened'
    op.repository = 55
    op.issue = 46
    op.where = 'github'
    load_it('label-was-attached', fb)
    f = fb.query('(and (eq what "issue-was-opened") (eq repository 50))').each.to_a
    assert_equal(0, f.count)
    f = fb.query('(and (eq issue 46) (eq repository 50))').each.to_a
    assert_equal(0, f.count)
    f = fb.query('(and (eq issue 46) (eq repository 55))').each.to_a
    assert_equal(1, f.count)
    assert_equal(46, f.first.issue)
    assert_equal(55, f.first.repository)
  end
end
