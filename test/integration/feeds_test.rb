# frozen_string_literal: true

# Redmine - project management software
# Copyright (C) 2006-2020  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

class FeedsTest < Redmine::IntegrationTest
  fixtures :projects, :trackers, :issue_statuses, :issues,
           :enumerations, :users, :issue_categories,
           :projects_trackers, :enabled_modules,
           :roles, :member_roles, :members

  def test_feeds_should_include_icon_tag
    host_name = 'feeds_test'

    with_settings :host_name => host_name do
      get '/projects.atom'
    end
    assert_response :success

    assert_select 'feed' do
      assert_select 'title'
      assert_select 'link[rel=?][href=?]', 'self', "http://#{host_name}/projects.atom"
      assert_select 'link[rel=?][href=?]', 'alternate', "http://#{host_name}/projects"
      assert_select 'id', :text => 'http://www.example.com/'
      assert_select 'icon', :text => %r{^http://www.example.com/favicon.ico}
      assert_select 'updated'
      assert_select 'generator', :text => Redmine::Info.app_name
    end
  end
end
