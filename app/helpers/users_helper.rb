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

module UsersHelper
  include ApplicationHelper

  def users_status_options_for_select(selected)
    user_count_by_status = User.group('status').count.to_hash
    options_for_select([[l(:label_all), '']] + (User.valid_statuses.map {|c| ["#{l('status_' + User::LABEL_BY_STATUS[c])} (#{user_count_by_status[c].to_i})", c]}), selected.to_s)
  end

  def user_mail_notification_options(user)
    user.valid_notification_options.collect {|o| [l(o.last), o.first]}
  end

  def textarea_font_options
    [[l(:label_font_default), '']] + UserPreference::TEXTAREA_FONT_OPTIONS.map {|o| [l("label_font_#{o}"), o]}
  end

  def history_default_tab_options
    [[l('label_issue_history_notes'), 'notes'],
     [l('label_history'), 'history'],
     [l('label_issue_history_properties'), 'properties'],
     [l('label_time_entry_plural'), 'time_entries'],
     [l('label_associated_revisions'), 'changesets'],
     [l('label_last_tab_visited'), 'last_tab_visited']]
  end

  def change_status_link(user)
    url = {:controller => 'users', :action => 'update', :id => user, :page => params[:page], :status => params[:status], :tab => nil}

    if user.locked?
      link_to l(:button_unlock), url.merge(:user => {:status => User::STATUS_ACTIVE}), :method => :put, :class => 'icon icon-unlock'
    elsif user.registered?
      link_to l(:button_activate), url.merge(:user => {:status => User::STATUS_ACTIVE}), :method => :put, :class => 'icon icon-unlock'
    elsif user != User.current
      link_to l(:button_lock), url.merge(:user => {:status => User::STATUS_LOCKED}), :method => :put, :class => 'icon icon-lock'
    end
  end

  def additional_emails_link(user)
    if user.email_addresses.count > 1 || Setting.max_additional_emails.to_i > 0
      link_to l(:label_email_address_plural), user_email_addresses_path(@user), :class => 'icon icon-email-add', :remote => true
    end
  end

  def user_settings_tabs
    tabs = [{:name => 'general', :partial => 'users/general', :label => :label_general},
            {:name => 'memberships', :partial => 'users/memberships', :label => :label_project_plural}
            ]
    if Group.givable.any?
      tabs.insert 1, {:name => 'groups', :partial => 'users/groups', :label => :label_group_plural}
    end
    tabs
  end

  def users_to_csv(users)
    Redmine::Export::CSV.generate(:encoding => params[:encoding]) do |csv|
      columns = [
        'login',
        'firstname',
        'lastname',
        'mail',
        'admin',
        'status',
        'created_on',
        'updated_on',
        'last_login_on',
        'passwd_changed_on'
      ]
      user_custom_fields = UserCustomField.all

      # csv header fields
      csv << columns.map {|column| l('field_' + column)} + user_custom_fields.pluck(:name)
      # csv lines
      users = users.preload(:custom_values)
      users.each do |user|
        values = columns.map {|c| c == 'status' ? l("status_#{User::LABEL_BY_STATUS[user.status]}") : user.send(c)} +
                 user_custom_fields.map {|custom_field| user.custom_value_for(custom_field)}

        csv << values.map do |value|
          format_object(value, false) do |v|
            case v.class.name
            when 'Float'
              sprintf('%.2f', v).gsub('.', l(:general_csv_decimal_separator))
            else
              v
            end
          end
        end
      end
    end
  end
end
