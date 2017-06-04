#! /usr/bin/env ruby -S rspec
# frozen_string_literal: true

require 'spec_helper'
require 'rspec-puppet'

describe 'accounts_group_members' do
  describe 'basic usage ' do
    it 'should raise an error if run with extra arguments' do
      is_expected.to run.with_params(1, 2, 3, 4).and_raise_error(Puppet::ParseError)
    end

    it 'should raise an error with incorrect type of arguments' do
      is_expected.to run.with_params(1, 2).and_raise_error(Puppet::ParseError)
    end

    it 'should raise an error when running without arguments' do
      is_expected.to run.with_params(nil).and_raise_error(Puppet::ParseError)
    end

    it 'should raise an error when given incorrect type' do
      is_expected.to run.with_params([]).and_raise_error(Puppet::ParseError)
    end
  end

  describe 'extract group members' do
    it 'find groups assignments' do
      users = {
        foo: { 'groups' => ['sudo', 'users']},
        john: { 'groups' => ['bar', 'users']},
      }

      is_expected.to run.with_params(users, {}).and_return(
        {
          'sudo' => {'members' => [:foo], 'require'=> ['User[foo]']},
          'bar' => {'members' => [:john],'require'=> ['User[john]']},
          'users' => {'members' => [:foo,:john], 'require'=> ['User[foo]','User[john]']},
          'foo' => {'members' => ['foo:primary'], 'require' => ['User[foo]']},
          'john' => {'members' => ['john:primary'], 'require' => ['User[john]']},
        }
      )
    end

    it 'skips absent users' do
      users = {
        alice: { 'groups' => ['users']},
        bob: { 'groups' => ['sudo', 'users']},
        tracy: { 'groups' => ['sudo', 'users'], 'ensure' => 'absent'},
      }

      is_expected.to run.with_params(users, {}).and_return(
        {
          'alice' => {'members' => ['alice:primary'], 'require'=> ['User[alice]']},
          'bob' => {'members' => ['bob:primary'], 'require'=> ['User[bob]']},
          'sudo' => {'members' => [:bob], 'require'=> ['User[bob]']},
          'users' => {
            'members' => [:alice,:bob],
            'require'=> ['User[alice]', 'User[bob]']
          },
        }
      )
    end
  end

  describe 'do not extract primary groups' do
    it 'finds group specified by primary_group' do
      users = {
        foo: { 'primary_group' => 'testgroup', 'manage_group' => true},
      }

      is_expected.to run.with_params(users, {}).and_return(
        {'testgroup' => {'members' => ['foo:primary'], 'require' => ['User[foo]']}}
      )
    end

    it 'finds group with gid' do
      users = {
        foo: { 'primary_group' => 'testgroup',
          'manage_group' => true, 'gid' => 123,
          'require' => []},
      }

      is_expected.to run.with_params(users, {}).and_return(
        {"testgroup"=>{"members"=>['foo:primary'], "require"=>['User[foo]'], "gid"=>123}}
      )
    end
  end
end
