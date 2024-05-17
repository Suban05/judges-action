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

# Fake GitHub client, for tests.
class FakeOctokit
  def rate_limit
    o = Object.new
    def o.remaining
      100
    end
    o
  end

  def add_comment(repo, issue, text)
    # nothing
  end

  def search_issues(_query)
    {
      items: [
        {
          number: 42,
          labels: [
            {
              name: 'bug'
            }
          ]
        }
      ]
    }
  end

  def repository_events(repo)
    [
      {
        id: 123,
        repo: {
          id: 42,
          name: repo
        },
        type: 'PushEvent',
        payload: {
          push_id: 42
        },
        created_at: Time.now
      },
      {
        id: 124,
        repo: {
          id: 42,
          name: repo
        },
        type: 'IssuesEvent',
        payload: {
          action: 'closed',
          issue: {
            number: 42
          }
        },
        created_at: Time.now
      },
      {
        id: 125,
        repo: {
          id: 42,
          name: repo
        },
        type: 'IssuesEvent',
        payload: {
          action: 'opened',
          issue: {
            number: 42
          }
        },
        created_at: Time.now
      }
    ]
  end
end